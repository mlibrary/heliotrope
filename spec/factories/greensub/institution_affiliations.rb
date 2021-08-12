# frozen_string_literal: true

FactoryBot.define do
  factory :institution_affiliation, class: Greensub::InstitutionAffiliation do
    institution { create(:institution) }
    dlps_institution_id { institution.identifier }
    affiliation { "member" }
  end
end
