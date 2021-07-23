# frozen_string_literal: true

class SeedInstitutionAffiliationsJob < ApplicationJob
  def perform(prefix = false)
    Greensub::Institution.all.each do |institution|
      dlps_institution_id = /(\d+)/.match(institution.identifier)[0]
      institution.identifier = dlps_institution_id
      institution.identifier = "#" + institution.identifier if prefix
      institution.save
      Greensub::InstitutionAffiliation.find_or_create_by(institution_id: institution.id, dlps_institution_id: dlps_institution_id, affiliation: 'member').save
    end
    true
  end
end
