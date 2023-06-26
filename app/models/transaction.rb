class Transaction < ApplicationRecord
  scope :reviewed, -> { where(reviewed: true) }
  scope :pending_review, -> { where(reviewed: false) }

  validates :name, :amount, presence: true

  belongs_to :merchant
  belongs_to :category

  accepts_nested_attributes_for :category
end
