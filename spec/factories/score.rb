# frozen_string_literal: true

FactoryBot.define do
  factory :score, aliases: [:private_score] do
    transient do
      user { FactoryBot.create(:user) }
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    sequence(:title) { |n| ["Test Score #{n}"] }
    press { FactoryBot.create(:press, subdomain: Services.score_press).subdomain }
    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    date_uploaded { Time.now }

    factory :public_score do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
  end
end
