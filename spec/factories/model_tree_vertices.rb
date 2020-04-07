# frozen_string_literal: true

FactoryBot.define do
  factory :model_tree_vertex do
    sequence(:noid) { |n| format("%09d", n) }
  end
end
