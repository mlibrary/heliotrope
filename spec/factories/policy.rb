# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    agent_type { "type" }
    agent_id { "id" }
    agent_token { "token" }
    credential_type { "type" }
    credential_id { "id" }
    credential_token { "token" }
    resource_type { "type" }
    resource_id { "id" }
    resource_token { "token" }
    zone_id { "id" }
  end
end
