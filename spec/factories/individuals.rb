# frozen_string_literal: true

FactoryBot.define do
  factory :individual do
    sequence(:identifier) { |n| ["Identifier#{n}"] }
    sequence(:name) { |n| ["Name#{n}"] }
    sequence(:email) { |n| ["Email#{n}"] }
  end
end
