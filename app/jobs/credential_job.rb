# frozen_string_literal: true

class CredentialJob < ApplicationJob
  def perform
    # Convert to Full License
    Checkpoint::DB::Grant.all.each do |grant|
      next unless grant.credential_type == 'permission' || grant.credential_id == 'read' || grant.credential_token == 'permission:read'

      license = Greensub::FullLicense.create
      grant.credential_type = 'License'
      grant.credential_id = license.id.to_s
      grant.credential_token = "License:#{license.id}"
      grant.save
    end

    # Remove Duplicates
    Checkpoint::DB::Grant.all.each do |grant|
      grants = Checkpoint::DB::Grant.where(agent_type: grant.agent_type, agent_id: grant.agent_id,
                                           credential_type: grant.credential_type,
                                           resource_type: grant.resource_type, resource_id: grant.resource_id)
      next unless grants.count > 1

      grant.delete
    end
    true
  end
end
