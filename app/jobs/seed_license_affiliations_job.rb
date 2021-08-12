# frozen_string_literal: true

class SeedLicenseAffiliationsJob < ApplicationJob
  def perform
    Greensub::License.all.each do |license|
      if license.licensee.is_a? Greensub::Institution
        Greensub::LicenseAffiliation.find_or_create_by(license_id: license.id, affiliation: 'member').save
      else
        Greensub::LicenseAffiliation.where(license_id: license.id).destroy_all
      end
    end
    true
  end
end
