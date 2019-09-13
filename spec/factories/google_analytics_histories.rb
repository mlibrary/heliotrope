# frozen_string_literal: true

FactoryBot.define do
  factory :google_analytics_history do
    noid { "MyString" }
    original_date { "MyString" }
    page_path { "/concern/thing" }
    pageviews { 4 }
  end
end
