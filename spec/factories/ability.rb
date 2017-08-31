# frozen_string_literal: true

FactoryGirl.define do
  factory :ability, class: Ability do
    initialize_with { new(build(:user), {}) }
  end
end
