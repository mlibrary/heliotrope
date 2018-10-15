# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Policy, type: :model do
  subject(:policy) { described_class.new }

  let(:attributes) do
    {
      agent_type: 'any',
      agent_id: 'any',
      agent_token: 'any:any',
      credential_type: 'permission',
      credential_id: 'read',
      credential_token: 'permission:read',
      resource_type: 'any',
      resource_id: 'any',
      resource_token: 'any:any',
      zone_id: Checkpoint::DB::Permit.default_zone
    }
  end

  before { PermissionService.clear_permits_table }

  it do
    expect(policy.valid?).to be false
    policy.set(attributes)
    expect(policy.valid?).to be true
    expect(policy.persisted?).to be false
    policy.save
    expect(policy.persisted?).to be true
  end
end
