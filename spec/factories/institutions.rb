# frozen_string_literal: true

FactoryBot.define do
  factory :institution do
    sequence(:identifier) { |n| "InstitutionIdentifier#{n}" }
    sequence(:name) { |n| "InstitutionName#{n}" }
    sequence(:entity_id) { |n| "InstitutionEntity_ID#{n}" }
    sequence(:site) { |n| "InstitutionSite#{n}" }
    sequence(:login) { |n| "InstitutionLogin#{n}" }
  end
end
