# frozen_string_literal: true

FactoryBot.define do
  factory :lessee do
    sequence(:identifier) { |n| ["Identifier#{n}"] }
  end
end
