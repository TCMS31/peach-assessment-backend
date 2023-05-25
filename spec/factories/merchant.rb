# frozen_string_literal: true

FactoryBot.define do
  factory :merchant do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  end
end
