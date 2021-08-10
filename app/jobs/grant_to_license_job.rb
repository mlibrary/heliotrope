# frozen_string_literal: true

class GrantToLicenseJob < ApplicationJob
  def perform # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    Checkpoint::DB::Grant.where(credential_type: 'License').each do |grant|
      license = Greensub::License.find(grant.credential_id)
      next if license.nil?

      if license.type == "Greensub::License"
        # this type of "no" or "abstract" license shouldn't exist anymore.
        license.license_affiliations.destroy_all
        Checkpoint::DB::Grant.where(credential_type: 'License', credential_id: license.id).destroy
        license.destroy!
      else
        # update all other licenses
        license.product_id = grant.resource_id if license.product_id.nil?
        license.licensee_id = grant.agent_id if license.licensee_id.nil?

        if license.licensee_type.nil?
          license.licensee_type = if grant.agent_type == "Individual"
                                    "Greensub::Individual"
                                  else
                                    "Greensub::Institution"
                                  end
        end

        license.save!
      end
    end
    true
  end
end
