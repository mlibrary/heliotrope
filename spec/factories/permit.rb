# frozen_string_literal: true

FactoryBot.define do
  factory :permit do
    agent_type { "agent_type" }
    agent_id { "agent_id" }
    agent_token { "agent_token" }
    credential_type { "credential_type" }
    credential_id { "credentail_id" }
    credential_token { "credential_token" }
    resource_type { "resource_type" }
    resource_id { "resource_id" }
    resource_token { "resource_token" }
    zone_id { "zone_id" }
  end
end
