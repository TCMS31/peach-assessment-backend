require 'database_cleaner'
require 'csv'

class Seeds
  COLOR_SCALE_GREEN = '#DDF1A3'
  COLOR_SCALE_RED = '#FFC9C9'
  COLOR_SCALE_BLUE = '#B6E4FB'
  COLOR_SCALE_PINK = '#FFDAF9'
  COLOR_SCALE_BROWN = '#E5CBAF'
  COLOR_SCALE_YELLOW = '#FFECC6'
  COLOR_SCALE_PURPLE = '#C5C8FF'

  CATEGORIES_MAP = [
    # INCOME
    ["Income", "🤑", COLOR_SCALE_GREEN],

    # SPENDING
    ["Food and Drink", "🍕", COLOR_SCALE_RED],
    ["Healthcare", "🏥", COLOR_SCALE_BROWN],
    ["Shops", "🛍", COLOR_SCALE_BLUE],
    ["Subscription Service", "📺", COLOR_SCALE_PINK],
    ["Travel", "✈️", COLOR_SCALE_YELLOW],
    ["Taxes", "💸", COLOR_SCALE_PURPLE],
  ]

  MERCHANTS  = ['Uber', 'United', 'Chipotle', 'Payroll', 'Amazon', 'Turbo Tax', 'Blue Cross', 'AMC', 'Netflix', 'Hulu']

  def update
      clean_db
      create_categories
      create_merchants
      create_transactions
      Rails.logger.info('Database is seeded')
  end

  private

  def clean_db
    DatabaseCleaner.clean_with :truncation
    Rails.logger.info('Database is cleaned')
  end

  def create_categories
    CATEGORIES_MAP.each do |c|
      name = c[0]
      emoji = c[1]
      color = c[2]

      Category.create(
        name: name,
        emoji: emoji,
        color: color,
      )
    end

    Rails.logger.info('Added Categories')
  end

  def create_merchants
    MERCHANTS.each do |m|
      Merchant.create(
        name: m,
      )
    end

    Rails.logger.info('Added Merchants')
  end

  def create_transactions
    transactions_from_csv.each do |transaction|
      merchant = Merchant.find_by_name(transaction['Merchant'])
      category = Category.find_by_name(transaction['Category'])

      Transaction.create!(
        name: transaction['Transaction Name'],
        amount: transaction['Amount'],
        date: Date.strptime(transaction['Date'], '%m/%d/%Y'),
        category_id: category&.id,
        merchant_id: merchant&.id
      )
    end

    Rails.logger.info('Added Transactions')
  end

  def transactions_from_csv
    csv_text = File.read(Rails.root.join('transactions.csv'))
    CSV.parse(csv_text, headers: true, strip: true)
  end
end

Seeds.new.update
