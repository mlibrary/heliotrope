# frozen_string_literal: true

class LicenseToGrantJob < ApplicationJob
  def perform
    Greensub::License.all.each do |license|
      grants = Checkpoint::DB::Grant.where(agent_type: license.licensee.agent_type.to_s,
                                          agent_id: license.licensee.agent_id.to_i,
                                          credential_type: license.credential_type.to_s,
                                          credential_id: license.credential_id.to_i,
                                          resource_type: license.product.resource_type.to_s,
                                          resource_id: license.product.resource_id.to_i)
      next if grants.first.present?

      Authority.grant!(Authority.agent(license.licensee.agent_type, license.licensee.agent_id),
                       Authority.credential(license.credential_type, license.credential_id),
                       Authority.resource(license.product.resource_type, license.product.resource_id))
    end
    true
  end
end
