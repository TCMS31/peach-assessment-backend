# frozen_string_literal: true

require 'rails_helper'
require 'tempfile'
require Rails.root.join('lib/seeds')

# The importer against CSVs other than the shipped fixture: the shapes a real
# bank export or a hand-edited file takes.
RSpec.describe Seeds, type: :model do
  let(:header) { "Transaction Name, Merchant, Amount, Date, Category,\n" }

  def import(body, bom: false)
    Tempfile.create(['ledger', '.csv']) do |file|
      file.write((bom ? "\uFEFF" : '') + header + body)
      file.flush
      described_class.run(logger: Logger.new(File::NULL), source: file.path)
    end
  end

  def amounts
    Transaction.order(:id).pluck(:amount).map(&:to_s)
  end

  it 'reads a file that starts with a UTF-8 byte-order mark, as Excel saves it' do
    import("Uber, Uber, 45.12, 5/29/2023, Shops,\n", bom: true)

    expect(Transaction.pluck(:name)).to eq(['Uber'])
  end

  it 'skips blank lines instead of failing on an empty row' do
    import("Uber, Uber, 45.12, 5/29/2023, Shops,\n\n\nHulu, Hulu, 6.99, 5/28/2023, Shops,\n\n")

    expect(Transaction.count).to eq(2)
  end

  it 'matches categories and merchants case-insensitively, as the unique indexes do' do
    import("Uber, uber, 45.12, 5/29/2023, shops,\n")

    expect(Category.where('LOWER(name) = ?', 'shops').count).to eq(1)
    expect(Merchant.where('LOWER(name) = ?', 'uber').count).to eq(1)
    expect(Transaction.last.category.name).to eq('Shops')
  end

  it 'keeps two identical rows on the same day as two transactions' do
    row = "Coffee, Chipotle, 4.50, 5/29/2023, Food and Drink,\n"
    import(row * 2)
    import(row * 2)

    expect(Transaction.where(name: 'Coffee').count).to eq(2)
    expect(Transaction.where(name: 'Coffee').sum(:amount)).to eq(BigDecimal('9.00'))
  end

  it 'stores amounts exactly, including three decimal places and money in' do
    import("A, Uber, 0.005, 5/29/2023, Shops,\nB, Uber, -2100.54, 5/29/2023, Shops,\n")

    expect(amounts).to eq(%w[0.005 -2100.54])
  end

  {
    'a currency symbol' => '$45.12',
    'a thousands separator' => '"1,200.00"',
    'more decimals than the column holds' => '12.3456',
    'a blank amount' => '',
    'text' => 'twelve'
  }.each do |description, amount|
    it "rejects #{description} with the line number instead of coercing it" do
      expect { import("Uber, Uber, 1.00, 5/29/2023, Shops,\nBad, Uber, #{amount}, 5/29/2023, Shops,\n") }
        .to raise_error(Seeds::ImportError, /line 3: cannot parse amount/)
      expect(Transaction.count).to eq(0)
    end
  end

  it 'rejects a two-digit year rather than importing the year 23 AD' do
    expect { import("Uber, Uber, 45.12, 5/29/23, Shops,\n") }
      .to raise_error(Seeds::ImportError, %r{line 2: cannot parse date "5/29/23"})
  end

  it 'rejects an impossible date' do
    expect { import("Uber, Uber, 45.12, 2/30/2023, Shops,\n") }
      .to raise_error(Seeds::ImportError, /line 2: cannot parse date/)
  end

  it 'rejects a row with no transaction name' do
    expect { import(", Uber, 45.12, 5/29/2023, Shops,\n") }
      .to raise_error(Seeds::ImportError, /line 2: missing transaction name/)
  end

  it 'files a row with no category under "Uncategorised" rather than failing' do
    import("Uber, Uber, 45.12, 5/29/2023, ,\n")

    expect(Transaction.last.category.name).to eq('Uncategorised')
  end
end
