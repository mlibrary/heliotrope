# frozen_string_literal: true

FactoryBot.define do
  factory :license_affiliation, class: Greensub::LicenseAffiliation do
    affiliation { "member" }
  end
end
