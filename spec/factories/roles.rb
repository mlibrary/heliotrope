# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    resource nil
    user { FactoryBot.create(:user) }
    role 'admin'
  end
end
