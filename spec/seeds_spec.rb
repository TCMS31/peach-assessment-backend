# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/seeds')

# The figures this API serves are only as good as the import that produced them.
# EXPECTED below was computed independently from transactions.csv (see
# docs/seeded-figures.md) and is written out row by row on purpose: an import
# bug that shifts a column or loses a decimal place has to change these literals
# to pass, which is exactly what a regression test is for.
module SeedFixtures
  EXPECTED = [
    ['Uber',           'Uber',       '45.12',    '2023-05-29', 'Shops'],
    ['SFO to JFK',     'United',     '129.97',   '2023-05-29', 'Shops'],
    ['Hulu',           'Hulu',       '6.99',     '2023-05-28', 'Shops'],
    ['Chipotle',       'Chipotle',   '12.88',    '2023-05-28', 'Shops'],
    ['Direct Deposit', 'Payroll',    '-2100.54', '2023-05-28', 'Shops'],
    ['Amazon',         'Amazon',     '70.24',    '2023-05-27', 'Shops'],
    ['Taxes 2022',     'Turbo Tax',  '110.0',    '2023-05-27', 'Shops'],
    ['Dr. Seuss',      'Blue Cross', '55.23',    '2023-05-27', 'Shops'],
    ['Fast X',         'AMC',        '25.99',    '2023-05-26', 'Shops'],
    ['Netflix',        'Netflix',    '9.99',     '2023-05-25', 'Shops']
  ].freeze

  NET_TOTAL = BigDecimal('-1634.13')
  MONEY_OUT = BigDecimal('466.41')
  MONEY_IN = BigDecimal('-2100.54')
end

RSpec.describe Seeds, type: :model do
  def seed!
    described_class.run(logger: Logger.new(File::NULL))
  end

  before { seed! }

  it 'runs from the db/seeds.rb entry point that `rails db:seed` uses' do
    expect { load Rails.root.join('db/seeds.rb').to_s }.not_to raise_error
  end

  it 'creates the seven categories and ten merchants exactly once' do
    expect(Category.count).to eq(7)
    expect(Merchant.count).to eq(10)
  end

  it 'gives every category a colour, which the client needs to draw the chart' do
    expect(Category.where(color: nil)).to be_empty
    expect(Category.where(emoji: nil)).to be_empty
  end

  it 'imports every CSV row with the exact name, merchant, amount, date and category' do
    imported = Transaction.includes(:category, :merchant).order(:id).map do |t|
      [t.name, t.merchant.name, t.amount.to_s, t.date.iso8601, t.category.name]
    end

    expect(imported).to match_array(SeedFixtures::EXPECTED)
  end

  it 'totals to the independently calculated figures' do
    expect(Transaction.sum(:amount)).to eq(SeedFixtures::NET_TOTAL)
    expect(Transaction.where(arel_table[:amount].gt(0)).sum(:amount)).to eq(SeedFixtures::MONEY_OUT)
    expect(Transaction.where(arel_table[:amount].lt(0)).sum(:amount)).to eq(SeedFixtures::MONEY_IN)
  end

  it 'is idempotent: re-seeding neither duplicates nor renames anything' do
    expect { seed! }
      .to not_change(Transaction, :count)
      .and not_change(Category, :count)
      .and not_change(Merchant, :count)
  end

  it 'preserves a review that a user has already made' do
    Transaction.find_by!(name: 'Netflix').update!(reviewed: true)

    seed!

    expect(Transaction.find_by!(name: 'Netflix').reviewed).to be(true)
  end

  it 'marks every imported row as pending review' do
    expect(Transaction.pending_review.count).to eq(10)
  end

  # Documented, not fixed: the fixture CSV files all ten rows - including a
  # payroll deposit and a tax payment - under "Shops". That is the ledger a
  # user is meant to correct in the app, so the importer reproduces it
  # faithfully rather than guessing better categories.
  it 'reproduces the fixture CSV as given, miscategorisations included' do
    expect(Transaction.joins(:category).where(categories: { name: 'Shops' }).count).to eq(10)
    expect(Transaction.joins(:category).where(categories: { name: 'Income' })).to be_empty
  end

  # rubocop:disable Rails/Delegate -- `delegate to: :Transaction` would resolve
  # against the example group, not the model.
  def arel_table
    Transaction.arel_table
  end
  # rubocop:enable Rails/Delegate
end
