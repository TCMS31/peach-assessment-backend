# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    name { Faker::Lorem.word }
    emoji { Faker::Lorem.word }
    color { Faker::Color.hex_color }
    budget { Faker::Number.decimal(l_digits: 2) }
  end
end
