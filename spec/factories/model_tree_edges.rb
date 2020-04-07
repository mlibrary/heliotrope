# frozen_string_literal: true

FactoryBot.define do
  factory :model_tree_edge do
    sequence(:parent_noid) { |n| format("%09d", (n * 2)) }
    sequence(:child_noid) { |n| format("%09d", (n * 2) + 1) }
  end
end
