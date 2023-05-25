# frozen_string_literal: true

module Transactions
  # The one write this API supports: a person reviews a transaction, optionally
  # correcting the category it was imported with.
  #
  # This exists because of a data-corruption bug in the original controller. The
  # model declared `accepts_nested_attributes_for :category` and the controller
  # permitted `category_attributes: [:name, :emoji]`. For a `belongs_to` with no
  # `id` in the nested hash, Active Record's one-to-one nested-attribute writer
  # falls through to `build_category`, so every recategorisation *created a new
  # category row* carrying only a name and an emoji:
  #
  #     categories before: [[25, "Travel", "#FFECC6"]]
  #     categories after : [[25, "Travel", "#FFECC6"], [26, "Food and Drink", nil]]
  #
  # Two consequences. `GET /categories` accumulated a duplicate per review, and
  # the new row had `color: nil`, so the mobile client's donut chart fell back to
  # its placeholder grey for exactly the categories a user had just fixed.
  #
  # Categories are reference data, so this class resolves one instead of minting
  # one: by id when the client sends `category_id`, otherwise by name for the
  # `category_attributes` shape the shipped client still uses.
  class Review
    Result = Struct.new(:transaction, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def self.call(...)
      new(...).call
    end

    def initialize(transaction, attributes)
      @transaction = transaction
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      category = resolve_category
      return failure(@category_error) if @category_error

      @transaction.category = category if category
      @transaction.reviewed = reviewed_flag unless reviewed_flag.nil?

      return failure(@transaction.errors.full_messages) unless @transaction.save

      Result.new(transaction: @transaction, errors: [])
    end

    private

    def failure(messages)
      Result.new(transaction: @transaction, errors: Array(messages))
    end

    def reviewed_flag
      return @reviewed_flag if defined?(@reviewed_flag)

      @reviewed_flag = ActiveModel::Type::Boolean.new.cast(@attributes[:reviewed])
    end

    def resolve_category
      return find_category_by_id if @attributes[:category_id].present?
      return find_or_create_category_by_name if category_attributes.present?

      nil
    end

    def find_category_by_id
      category = Category.find_by(id: @attributes[:category_id])
      @category_error = ["Category #{@attributes[:category_id]} does not exist"] if category.nil?
      category
    end

    # The legacy `category_attributes` shape. Matching on name is what the client
    # means by it: the picker offers the names returned by `GET /categories`.
    # A genuinely new name is still allowed through, but only once.
    def find_or_create_category_by_name
      name = category_attributes[:name].to_s.strip
      if name.empty?
        @category_error = ['Category name cannot be blank']
        return nil
      end

      existing = Category.where('LOWER(name) = ?', name.downcase).first
      return existing if existing

      Category.create!(name: name, emoji: category_attributes[:emoji])
    end

    def category_attributes
      @category_attributes ||= (@attributes[:category_attributes] || {}).to_h.symbolize_keys
    end
  end
end
