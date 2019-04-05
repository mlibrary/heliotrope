# frozen_string_literal: true

FactoryBot.define do
  factory :component, class: Greensub::Component do
    sequence(:identifier) { |n| "ComponentIdentifier#{n}" }
    sequence(:name) { |n| "ComponentName#{n}" }
    sequence(:noid) { |n| "ComponentNoid#{n}" }
  end
end
