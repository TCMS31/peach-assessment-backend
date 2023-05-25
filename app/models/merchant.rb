# frozen_string_literal: true

# Reference data: who the money went to or came from.
class Merchant < ApplicationRecord
  # See Category: transactions outlive the reference rows that describe them.
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # LOWER(name) so the order does not depend on the database collation
  # ("AMC" sorts before "Amazon" under C/musl, after it under en_US).
  scope :ordered, -> { order(arel_table[:name].lower, :id) }
  # Matches the unique index on LOWER(name).
  scope :named, ->(name) { where('LOWER(name) = LOWER(?)', name.to_s) }
end
