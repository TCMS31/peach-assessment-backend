# frozen_string_literal: true

# One line of the imported ledger. `amount` is positive for money out and
# negative for money in, matching the source CSV.
#
# `accepts_nested_attributes_for :category` used to live here. It is gone on
# purpose: on a `belongs_to` with no `id` in the nested hash it builds a brand
# new category on every write, which duplicated reference data and dropped the
# category colour. Category resolution now happens in Transactions::Review.
class Transaction < ApplicationRecord
  belongs_to :merchant
  belongs_to :category

  validates :name, presence: true
  # `date` is `null: false` in the schema but had no model validation, so a
  # missing date surfaced as a PG::NotNullViolation (500) rather than a 422.
  validates :date, presence: true
  validates :amount, presence: true, numericality: true

  scope :reviewed, -> { where(reviewed: true) }
  scope :pending_review, -> { where(reviewed: false) }
  scope :newest_first, -> { order(date: :desc, id: :desc) }
end
