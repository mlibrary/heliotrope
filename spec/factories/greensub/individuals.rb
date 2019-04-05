# frozen_string_literal: true

FactoryBot.define do
  factory :individual, class: Greensub::Individual do
    sequence(:identifier) { |n| "IndividualIdentifier#{n}" }
    sequence(:name) { |n| "IndividualName#{n}" }
    sequence(:email) { |n| "IndividualEmail#{n}" }
  end
end
