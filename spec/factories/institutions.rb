# frozen_string_literal: true

FactoryBot.define do
  factory :institution do
    sequence(:identifier) { |n| ["Identifier#{n}"] }
    sequence(:name) { |n| ["Name#{n}"] }
    sequence(:entity_id) { |n| ["Entity_ID#{n}"] }
    sequence(:site) { |n| ["Site#{n}"] }
    sequence(:login) { |n| ["Login#{n}"] }
  end
end
