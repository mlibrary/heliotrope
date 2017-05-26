# frozen_string_literal: true

FactoryGirl.define do
  factory :permission_template_access, class: Hyrax::PermissionTemplateAccess do
    permission_template

    trait :manage do
      access 'manage'
    end

    trait :view do
      access 'view'
    end
  end
end
