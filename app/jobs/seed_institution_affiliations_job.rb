# frozen_string_literal: true

class SeedInstitutionAffiliationsJob < ApplicationJob
  def perform
    Greensub::Institution.all.each do |institution|
      Greensub::InstitutionAffiliation.find_or_create_by(institution_id: institution.id, dlps_institution_id: institution.identifier, affiliation: 'member').save
    end
    true
  end
end
