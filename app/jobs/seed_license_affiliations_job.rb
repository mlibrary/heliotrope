# frozen_string_literal: true

class SeedLicenseAffiliationsJob < ApplicationJob
  def perform
    Greensub::License.all.each do |license|
      Greensub::LicenseAffiliation.find_or_create_by(license_id: license.id, affiliation: 'member').save
    end
    true
  end
end
