# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Policy, type: :model do
  subject(:policy) { described_class.new }

  let(:attributes) do
    {
      agent_type: "agent_type",
      agent_id: "agent_id",
      agent_token: "agent_token",
      credential_type: "credential_type",
      credential_id: "credentail_id",
      credential_token: "credential_token",
      resource_type: "resource_type",
      resource_id: "resource_id",
      resource_token: "resource_token",
      zone_id: "zone_id"
    }
  end

  it do
    expect(policy.valid?).to be false
    policy.set(attributes)
    expect(policy.valid?).to be true
    expect(policy.persisted?).to be false
    policy.save
    expect(policy.persisted?).to be true
  end
end
