# frozen_string_literal: true

FactoryBot.define do
  factory :institution, class: Greensub::Institution do
    sequence(:identifier) { |n| n }
    sequence(:name) { |n| "InstitutionName#{n}" }
    sequence(:display_name) { |n| "InstitutionDisplayName#{n}" }
    sequence(:entity_id) { |n| "InstitutionEntityID#{n}" }
    sequence(:catalog_url) { |n| "InstitutionCatalogURL#{n}" }
    sequence(:link_resolver_url) { |n| "InstitutionLinkResolverURL#{n}" }
    sequence(:location) { |n| "InstitutionLocation#{n}" }
    sequence(:horizontal_logo) { |n| "InstitutionHorizontalLogo#{n}" }
    sequence(:vertical_logo) { |n| "InstitutionVerticalLogo#{n}" }
    sequence(:ror_id) { |n| "InstitutionRorID#{n}" }
    sequence(:site) { |n| "InstitutionSite#{n}" }
  end
end
