# frozen_string_literal: true

FactoryBot.define do
  factory :aptrust_deposit do
    sequence(:noid) { |n| format("%09d", n) }
    sequence(:identifier) { |n| format("app-press-%09d", n) }
  end
end
