# frozen_string_literal: true

FactoryBot.define do
  factory :sub_brand do
    sequence(:title) { |n| "Sub-brand #{n}" }
    press { FactoryBot.create(:press) }
  end
end
