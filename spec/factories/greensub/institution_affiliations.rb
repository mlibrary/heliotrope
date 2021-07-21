# frozen_string_literal: true

FactoryBot.define do
  factory :institution_affiliation, class: Greensub::InstitutionAffiliation do
    institution { FactoryBot.create(:institution) }
    dlps_institution_id { Greensub::Institution.last.identifier }
    affiliation { "member" }
  end
end
