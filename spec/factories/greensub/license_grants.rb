# frozen_string_literal: true

FactoryBot.define do
  factory :license_grant, aliases: [:individual_license_grant], class: Greensub::LicenseGrant do
    agent_type { "Individual" }
    sequence(:agent_id, &:to_s)
    agent_token { "#{agent_type}:#{agent_id}" }
    credential_type { "License" }
    sequence(:credential_id, &:to_s)
    credential_token { "#{credential_type}:#{credential_id}" }
    resource_type { "Product" }
    sequence(:resource_id, &:to_s)
    resource_token { "#{resource_type}:#{resource_id}" }
    zone_id { "(all)" }

    factory :institution_license_grant do
      agent_type { "Institution" }
    end
  end
end
