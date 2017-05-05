# frozen_string_literal: true

FactoryGirl.define do
  factory :press do
    sequence(:name) { |n| "Press #{n}" }
    logo_path "MyString"
    description "MyText"
    sequence(:subdomain) { |_n| "press-#{srand}" }
  end
end
