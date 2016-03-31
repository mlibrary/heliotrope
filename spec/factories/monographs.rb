FactoryGirl.define do
  factory :monograph, aliases: [:private_monograph] do
    transient do
      user { FactoryGirl.create(:user) }
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    sequence(:title) { |n| ["Test Monograph #{n}"] }
    press { FactoryGirl.create(:press).subdomain }
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    factory :public_monograph do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end
end
