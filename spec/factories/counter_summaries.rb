# frozen_string_literal: true

FactoryBot.define do
  factory :counter_summary do
    monograph_noid { 'abc123def' }
    sequence(:month) { |n| ((n - 1) % 12) + 1 }
    sequence(:year) { |n| 2025 + ((n - 1) / 12) }

    total_item_requests_month { 100 }
    total_item_requests_life { 1000 }
    total_item_investigations_month { 150 }
    total_item_investigations_life { 1500 }
    unique_item_requests_month { 80 }
    unique_item_requests_life { 800 }
    unique_item_investigations_month { 120 }
    unique_item_investigations_life { 1200 }
  end
end
