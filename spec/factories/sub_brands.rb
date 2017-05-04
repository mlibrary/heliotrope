# frozen_string_literal: true

FactoryGirl.define do
  factory :sub_brand do
    sequence(:title) { |n| "Sub-brand #{n}" }
    press { FactoryGirl.create(:press) }
  end
end
