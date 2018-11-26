# frozen_string_literal: true

FactoryBot.define do
  factory :grant do
    agent_type { "Individual" }
    sequence(:agent_id, &:to_s)
    agent_token { "#{agent_type}:#{agent_id}" }
    credential_type { "permission" }
    credential_id { "read" }
    credential_token { "#{credential_type}:#{credential_id}" }
    resource_type { "Product" }
    sequence(:resource_id, &:to_s)
    resource_token { "#{resource_type}:#{resource_id}" }
    zone_id { "(all)" }
  end
end
