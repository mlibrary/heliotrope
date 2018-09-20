# frozen_string_literal: true

json.extract! permit, :id, :agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id
json.url permit_url(permit, format: :json)
