# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    sequence(:identifier) { |n| ["Identifier#{n}"] }
    sequence(:name) { |n| ["Name#{n}"] }
    sequence(:noid) { |n| ["Noid#{n}"] }
    sequence(:handle) { |n| ["Handle#{n}"] }
  end
end
