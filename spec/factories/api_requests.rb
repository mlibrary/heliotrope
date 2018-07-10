# frozen_string_literal: true

FactoryBot.define do
  factory :api_request do
    user nil
    action "MyString"
    path "MyString"
    params "MyString"
    status 1
    exception "MyString"
  end
end
