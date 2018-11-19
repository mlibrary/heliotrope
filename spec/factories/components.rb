# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    sequence(:identifier) { |n| "ComponentIdentifier#{n}" }
    sequence(:name) { |n| "ComponentName#{n}" }
    sequence(:noid) { |n| "ComponentNoid#{n}" }
    sequence(:handle) { |n| "ComponentHandle#{n}" }
  end
end
