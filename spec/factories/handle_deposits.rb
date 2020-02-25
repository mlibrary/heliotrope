# frozen_string_literal: true

FactoryBot.define do
  factory :handle_deposit do
    sequence(:noid) { |n| format("%09d", n) }
    sequence(:action) { |n| n.even? ? 'create' : 'delete' }
  end
end
