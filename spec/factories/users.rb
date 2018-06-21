# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      press { FactoryBot.create(:press) }
    end

    sequence(:email) { |_n| "email-#{srand}@test.com" }

    encrypted_password { SecureRandom.urlsafe_base64(12) }

    factory :platform_admin do
      after(:create) do |user, _evaluator|
        user.roles.create role: 'admin', resource: nil
      end
    end

    factory :press_admin do
      after(:create) do |user, evaluator|
        user.roles.create role: 'admin', resource: evaluator.press
      end
    end

    factory :editor do
      after(:create) do |user, evaluator|
        user.roles.create role: 'editor', resource: evaluator.press
      end
    end
  end
end
