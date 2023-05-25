# frozen_string_literal: true

require 'csv'

# Imports the take-home's fixture ledger (transactions.csv) into the database.
#
# Two things changed from the generated version.
#
# 1. It no longer truncates. The old seeder's first step was
#    `DatabaseCleaner.clean_with :truncation`, and `database_cleaner` lives in
#    the development/test bundle - so `rake db:seed RAILS_ENV=production` either
#    exploded on `require` or, with the gem present, wiped the production
#    database. Seeding is now idempotent: run it as often as you like.
# 2. A CSV row naming a category or merchant that is not in the lists below used
#    to pass `nil` into a `null: false` column and surface as a raw PG error.
#    Unknown reference data is created; a malformed date is reported by line.
#
# This lives in lib/ rather than in db/seeds.rb so that the spec suite can load
# it once and invoke it repeatedly.
module Seeds
  COLORS = {
    green: '#DDF1A3',
    red: '#FFC9C9',
    blue: '#B6E4FB',
    pink: '#FFDAF9',
    brown: '#E5CBAF',
    yellow: '#FFECC6',
    purple: '#C5C8FF'
  }.freeze

  CATEGORIES = [
    { name: 'Income',               emoji: '🤑',  color: COLORS[:green] },
    { name: 'Food and Drink',       emoji: '🍕',  color: COLORS[:red] },
    { name: 'Healthcare',           emoji: '🏥',  color: COLORS[:brown] },
    { name: 'Shops',                emoji: '🛍',  color: COLORS[:blue] },
    { name: 'Subscription Service', emoji: '📺',  color: COLORS[:pink] },
    { name: 'Travel',               emoji: '✈️', color: COLORS[:yellow] },
    { name: 'Taxes',                emoji: '💸', color: COLORS[:purple] }
  ].freeze

  MERCHANTS = ['Uber', 'United', 'Chipotle', 'Payroll', 'Amazon', 'Turbo Tax',
               'Blue Cross', 'AMC', 'Netflix', 'Hulu'].freeze

  CSV_PATH = 'transactions.csv'
  DATE_FORMAT = '%m/%d/%Y'

  module_function

  def run(logger: Rails.logger)
    ActiveRecord::Base.transaction do
      create_categories
      create_merchants
      import_transactions
    end
    logger.info("Seeded #{Category.count} categories, #{Merchant.count} merchants, " \
                "#{Transaction.count} transactions")
  end

  def create_categories
    CATEGORIES.each do |attributes|
      Category.find_or_initialize_by(name: attributes[:name]).update!(attributes)
    end
  end

  def create_merchants
    MERCHANTS.each { |name| Merchant.find_or_create_by!(name: name) }
  end

  def import_transactions
    rows.each.with_index(2) { |row, line| import_row(row, line) }
  end

  def import_row(row, line)
    attributes = {
      name: row['Transaction Name'],
      amount: row['Amount'],
      date: parse_date(row['Date'], line),
      category: category_for(row['Category']),
      merchant: merchant_for(row['Merchant'])
    }

    # Keyed on name + date + merchant so a re-run does not duplicate the ledger,
    # and so a row a user has already reviewed keeps its review.
    Transaction
      .find_or_initialize_by(attributes.slice(:name, :date, :merchant))
      .update!(attributes)
  end

  def category_for(name)
    Category.find_or_create_by!(name: name.to_s.strip.presence || 'Uncategorised')
  end

  def merchant_for(name)
    Merchant.find_or_create_by!(name: name.to_s.strip.presence || 'Unknown')
  end

  def parse_date(value, line)
    Date.strptime(value.to_s.strip, DATE_FORMAT)
  rescue Date::Error
    raise ArgumentError, "#{CSV_PATH} line #{line}: cannot parse date #{value.inspect}"
  end

  def rows
    CSV.parse(Rails.root.join(CSV_PATH).read, headers: true, strip: true)
  end
end
