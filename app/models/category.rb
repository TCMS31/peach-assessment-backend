# frozen_string_literal: true

# Reference data: the fixed set of buckets a transaction can be filed under.
# `color` and `emoji` are presentation values the mobile client renders directly.
class Category < ApplicationRecord
  # `restrict_with_error`, not `destroy`. These are accounting records: deleting
  # a category must never silently delete the transactions filed under it.
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # LOWER(name) so the order does not depend on the database collation
  # ("AMC" sorts before "Amazon" under C/musl, after it under en_US).
  scope :ordered, -> { order(arel_table[:name].lower, :id) }
  # Matches the unique index on LOWER(name).
  scope :named, ->(name) { where('LOWER(name) = LOWER(?)', name.to_s) }
end
