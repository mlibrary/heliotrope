# frozen_string_literal: true

FactoryBot.define do
  factory :monograph, aliases: [:private_monograph] do
    transient do
      user { FactoryBot.create(:user) }
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    sequence(:title) { |n| ["Test Monograph #{n}"] }
    press { FactoryBot.create(:press).subdomain }
    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    # when a Monograph is created with the actor stack, `date_uploaded` and `date_modified` are set automatically
    date_uploaded { DateTime.now }
    date_modified { DateTime.now }

    factory :public_monograph do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end

    # https://github.com/samvera/hyrax/blob/b034218b89dde7df534e32d1e5ade9161e129a1d/spec/factories/generic_works.rb#L52-L56
    factory :monograph_with_one_file do
      before(:create) do |monograph, evaluator|
        monograph.ordered_members << create(:file_set, user: evaluator.user, title: ['A Contained FileSet'], label: 'filename.pdf')
      end
    end
  end
end
