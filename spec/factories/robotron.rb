# frozen_string_literal: true

FactoryBot.define do
  factory :robotron do
    sequence(:ip) { |n| format("10.0.0.%03d", n.modulo(256)) }
  end
end
