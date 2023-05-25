# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    name { Faker::Commerce.product_name }
    reviewed { false }
    amount { Faker::Number.decimal(l_digits: 3) }
    date { Faker::Date.backward(days: 30) }
    category
    merchant
  end
end
