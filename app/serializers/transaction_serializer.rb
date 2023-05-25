# frozen_string_literal: true

# `amount` stays a JSON string ("129.97"). It is a `decimal(22, 3)` column and
# Active Record serialises decimals as strings so no precision is lost passing
# through an IEEE-754 double. The client is responsible for parsing it, which
# the mobile app does in `src/domain/money.js`.
class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :name, :date, :amount, :reviewed

  belongs_to :merchant
  belongs_to :category
end
