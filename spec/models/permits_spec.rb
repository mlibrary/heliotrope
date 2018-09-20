# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permit, type: :model do
  subject(:permit) { described_class.new }

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
    is_expected.to be_a_kind_of(Checkpoint::DB::Permit)
    expect(permit.valid?).to be false
    permit.set(attributes)
    expect(permit.valid?).to be true
    expect(permit.persisted?).to be false
    permit.save
    expect(permit.persisted?).to be true
  end
end
