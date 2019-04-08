# frozen_string_literal: true

FactoryBot.define do
  factory :product, class: Greensub::Product do
    sequence(:identifier) { |n| "ProductIdentifier#{n}" }
    sequence(:name) { |n| "ProductName#{n}" }
    sequence(:purchase) { |n| "ProductPurchase#{n}" }
  end
end
