# frozen_string_literal: true

# Reference data: who the money went to or came from.
class Merchant < ApplicationRecord
  # See Category: transactions outlive the reference rows that describe them.
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }
end
