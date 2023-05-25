# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    # A sequence, not Faker::Lorem.word: category names are uniquely indexed and
    # Faker's word list is small enough that three draws collide often enough to
    # make the suite flaky.
    sequence(:name) { |n| "Category #{n}" }
    emoji { %w[🤑 🍕 🏥 🛍 📺 ✈️ 💸].sample }
    color { Faker::Color.hex_color }
    budget { Faker::Number.decimal(l_digits: 2) }
  end
end
