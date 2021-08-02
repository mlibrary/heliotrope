# frozen_string_literal: true

FactoryBot.define do
  factory :license_affiliation, class: Greensub::LicenseAffiliation do
    license { FactoryBot.create(:full_license) }
    affiliation { "member" }
  end
end
