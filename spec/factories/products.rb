# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:identifier) { |n| "ProductIdentifier#{n}" }
    sequence(:name) { |n| "ProductName#{n}" }
    sequence(:purchase) { |n| "ProductPurchase#{n}" }
  end
end
