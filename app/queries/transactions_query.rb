# frozen_string_literal: true

# Builds the `GET /transactions` relation from request parameters.
#
# Why a query object rather than branches in the controller:
#
# * The controller used `if params[:pending_review] ... elsif params[:reviewed]`.
#   Every query-string value is a *String*, so `"false"` and `"0"` are truthy and
#   `?pending_review=false` returned the pending list. Casting happens here, once,
#   through `ActiveModel::Type::Boolean`.
# * `Transaction.all` was unordered and unbounded. Postgres makes no ordering
#   promise without an `ORDER BY`, so paging an unordered relation can repeat one
#   row and skip another. Ordering and paging therefore live together.
# * Every association the serializer embeds is preloaded, turning the old
#   1 + 2N query pattern into a fixed three queries.
#
# Adding a filter is the one-line `register` call below: that is the extension
# seam a future developer actually needs.
class TransactionsQuery
  # Raised for a filter value the server cannot honour; rendered as a 400.
  class InvalidFilter < StandardError; end

  DEFAULT_PER_PAGE = 100
  MAX_PER_PAGE = 200

  # Associations the TransactionSerializer embeds.
  SERIALIZED_ASSOCIATIONS = %i[category merchant].freeze

  # Deliberately stricter than `ActiveModel::Type::Boolean`, which casts every
  # unrecognised string - "maybe", "no thanks", a typo - to `true`. A filter the
  # server cannot understand should be a 400, not a quietly different answer.
  TRUE_VALUES = %w[true t 1 yes y on].freeze
  FALSE_VALUES = %w[false f 0 no n off].freeze

  class << self
    def filters
      @filters ||= {}
    end

    # register(:merchant_id) { |scope, value| scope.where(merchant_id: value) }
    def register(name, &rule)
      filters[name.to_sym] = rule
    end

    def cast_boolean!(name, value)
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      normalized = value.to_s.strip.downcase
      return true if TRUE_VALUES.include?(normalized)
      return false if FALSE_VALUES.include?(normalized)

      raise InvalidFilter, "#{name} must be true or false"
    end

    def cast_id!(name, value)
      id = Integer(value.to_s, exception: false)
      raise InvalidFilter, "#{name} must be an integer" if id.nil?

      id
    end
  end

  # `reviewed=true|false` is the canonical filter.
  register(:reviewed) do |scope, value|
    scope.where(reviewed: cast_boolean!(:reviewed, value))
  end

  # `pending_review=true` is the spelling the mobile client already ships. It is
  # the inverse of `reviewed`, kept as a first-class alias rather than as a
  # special case buried in the controller.
  register(:pending_review) do |scope, value|
    scope.where(reviewed: !cast_boolean!(:pending_review, value))
  end

  register(:category_id) do |scope, value|
    scope.where(category_id: cast_id!(:category_id, value))
  end

  register(:merchant_id) do |scope, value|
    scope.where(merchant_id: cast_id!(:merchant_id, value))
  end

  def initialize(params = {}, scope: Transaction.all)
    @params = params
    @scope = scope
  end

  # The paged, ordered, preloaded relation.
  def results
    @results ||= ordered_scope.limit(per_page).offset((page - 1) * per_page)
  end

  # Total matching rows, ignoring pagination: one COUNT, no rows transferred.
  def total_count
    @total_count ||= filtered_scope.count
  end

  def page
    @page ||= positive_integer(@params[:page]) || 1
  end

  def per_page
    @per_page ||= [positive_integer(@params[:per_page]) || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
  end

  def total_pages
    return 1 if total_count.zero?

    (total_count.to_f / per_page).ceil
  end

  private

  def filtered_scope
    @filtered_scope ||= begin
      assert_filters_agree!
      self.class.filters.reduce(@scope) do |scope, (name, rule)|
        value = @params[name]
        value.blank? ? scope : rule.call(scope, value)
      end
    end
  end

  def ordered_scope
    filtered_scope
      .includes(*SERIALIZED_ASSOCIATIONS)
      .order(date: :desc, id: :desc)
  end

  # `?reviewed=true&pending_review=true` asks for two disjoint sets. The old
  # controller silently answered one of them; saying so is more useful.
  def assert_filters_agree!
    reviewed = @params[:reviewed]
    pending = @params[:pending_review]
    return if reviewed.blank? || pending.blank?

    return unless self.class.cast_boolean!(:reviewed, reviewed) ==
                  self.class.cast_boolean!(:pending_review, pending)

    raise InvalidFilter, 'reviewed and pending_review contradict each other'
  end

  def positive_integer(value)
    integer = Integer(value.to_s, exception: false)
    integer if !integer.nil? && integer.positive?
  end
end
