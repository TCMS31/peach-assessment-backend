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
#    Unknown reference data is created; a malformed row is reported by line.
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
  # Four-digit years only: `Date.strptime('5/29/23', '%m/%d/%Y')` happily
  # returns the year 23 AD instead of failing.
  DATE_PATTERN = %r{\A\d{1,2}/\d{1,2}/\d{4}\z}
  # Plain decimals that fit `decimal(22, 3)`. Anything else ("$45.12",
  # "1,200.00", "12.3456") is rejected rather than coerced or silently rounded.
  AMOUNT_PATTERN = /\A-?\d{1,19}(?:\.\d{1,3})?\z/

  # A CSV row that cannot be imported. The message always names the line.
  class ImportError < ArgumentError; end

  module_function

  def run(logger: Rails.logger, source: Rails.root.join(CSV_PATH))
    ActiveRecord::Base.transaction do
      create_categories
      create_merchants
      import_transactions(source)
    end
    logger.info("Seeded #{Category.count} categories, #{Merchant.count} merchants, " \
                "#{Transaction.count} transactions")
  end

  def create_categories
    CATEGORIES.each do |attributes|
      (Category.named(attributes[:name]).first || Category.new).update!(attributes)
    end
  end

  def create_merchants
    MERCHANTS.each { |name| merchant_for(name) }
  end

  # Two identical rows on the same day (two coffees at the same shop) are two
  # transactions, so a row is matched to the n-th existing record with its
  # name, date and merchant rather than to the first one.
  def import_transactions(source)
    occurrences = Hash.new(0)
    rows(source).each.with_index(2) do |row, line|
      attributes = attributes_for(row, line)
      key = attributes.slice(:name, :date, :merchant)
      import_row(attributes, key, occurrences[key], line)
      occurrences[key] += 1
    end
  end

  # Keyed on name + date + merchant so a re-run does not duplicate the ledger,
  # and so a row a user has already reviewed keeps its review.
  def import_row(attributes, key, occurrence, line)
    record = Transaction.where(key).order(:id).offset(occurrence).first || Transaction.new
    record.update!(attributes)
  rescue ActiveRecord::RecordInvalid => e
    raise ImportError, "#{CSV_PATH} line #{line}: #{e.record.errors.full_messages.to_sentence}"
  end

  def attributes_for(row, line)
    {
      name: parse_name(row['Transaction Name'], line),
      amount: parse_amount(row['Amount'], line),
      date: parse_date(row['Date'], line),
      category: category_for(row['Category']),
      merchant: merchant_for(row['Merchant'])
    }
  end

  # Case-insensitive, like the unique indexes: "shops" in the CSV is the
  # existing "Shops" category, not a second one that the index would reject.
  def category_for(name)
    name = name.to_s.strip.presence || 'Uncategorised'
    Category.named(name).first || Category.create!(name: name)
  end

  def merchant_for(name)
    name = name.to_s.strip.presence || 'Unknown'
    Merchant.named(name).first || Merchant.create!(name: name)
  end

  def parse_name(value, line)
    value.to_s.strip.presence || raise(ImportError, "#{CSV_PATH} line #{line}: missing transaction name")
  end

  def parse_amount(value, line)
    text = value.to_s.strip
    return BigDecimal(text) if AMOUNT_PATTERN.match?(text)

    raise ImportError, "#{CSV_PATH} line #{line}: cannot parse amount #{value.inspect}"
  end

  def parse_date(value, line)
    text = value.to_s.strip
    return Date.strptime(text, DATE_FORMAT) if DATE_PATTERN.match?(text)

    raise ImportError, "#{CSV_PATH} line #{line}: cannot parse date #{value.inspect}"
  rescue Date::Error
    raise ImportError, "#{CSV_PATH} line #{line}: cannot parse date #{value.inspect}"
  end

  # `bom|utf-8` because a CSV saved from Excel starts with a byte-order mark,
  # which would otherwise become part of the first header and hide the
  # "Transaction Name" column. Blank lines (a trailing newline or two) are skipped.
  def rows(source)
    CSV.parse(File.read(source, encoding: 'bom|utf-8'), headers: true, strip: true, skip_blanks: true)
  end
end
