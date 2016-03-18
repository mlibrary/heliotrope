FactoryGirl.define do
  factory :user do
    transient do
      press { FactoryGirl.create(:press) }
    end

    sequence(:email) { |_n| "email-#{srand}@test.com" }
    password 'a password'
    password_confirmation 'a password'

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
  end
end
