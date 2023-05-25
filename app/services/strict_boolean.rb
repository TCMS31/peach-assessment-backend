# frozen_string_literal: true

# Casts request input to true/false, or nil when it is not a recognised
# spelling.
#
# Deliberately stricter than `ActiveModel::Type::Boolean`, which casts every
# unrecognised string - "maybe", "no thanks", a typo - to `true`. Both the list
# filters and the review write use it, so `reviewed=maybe` is refused on either
# path instead of quietly meaning "true".
module StrictBoolean
  TRUE_VALUES = %w[true t 1 yes y on].freeze
  FALSE_VALUES = %w[false f 0 no n off].freeze

  module_function

  def cast(value)
    return value if [true, false].include?(value)

    normalized = value.to_s.strip.downcase
    return true if TRUE_VALUES.include?(normalized)

    false if FALSE_VALUES.include?(normalized)
  end
end
