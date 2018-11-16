# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:identifier) { |n| ["Identifier#{n}"] }
    sequence(:name) { |n| ["Name#{n}"] }
    sequence(:purchase) { |n| ["Purchase#{n}"] }
  end
end
