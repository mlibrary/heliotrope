# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Policy, type: :model do
  let(:valid_attributes) do
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

  let(:invalid_attributes) do
    {
      agent_type: '',
      agent_id: '',
      agent_token: '',
      credential_type: '',
      credential_id: '',
      credential_token: '',
      resource_type: '',
      resource_id: '',
      resource_token: '',
      zone_id: Checkpoint::DB::Permit.default_zone
    }
  end

  before { PermissionService.clear_permits_table }

  context 'Class' do
    describe '#create (and #create!)' do
      subject { described_class.create(attributes) }

      context 'invalid attributes' do
        let(:attributes) { invalid_attributes }

        it { is_expected.to be nil }
      end

      context 'valid attributes' do
        let(:attributes) { valid_attributes }

        it { is_expected.to be_an_instance_of(described_class) }
      end
    end

    describe '#count' do
      subject { described_class.count }

      let(:count) { double('count') }

      before { allow(Checkpoint::DB::Permit).to receive(:count).and_return(count) }

      it { is_expected.to be count }
    end

    describe '#last' do
      subject { described_class.last }

      let(:last) { double('last') }

      before { allow(Checkpoint::DB::Permit).to receive(:last).and_return(last) }

      it do
        is_expected.to be_an_instance_of(described_class)
        expect(subject.permit).to eq last
      end
    end

    context 'policies' do
      let(:entity) { Entity.null_object }
      let(:token) { "#{EntityNullObject}:#{entity.id}" }
      let(:permit) { double('permit') }
      let(:permits) { [permit] }
      let(:policy) { double('policy') }
      let(:policies) { [policy] }

      before { allow(described_class).to receive(:new).with(permit).and_return(policy) }

      it '#agent_policies' do
        entity
        token
        allow(Checkpoint::DB::Permit).to receive(:where).with(agent_token: token).and_return(permits)
        expect(described_class.agent_policies(entity)).to eq policies
      end

      it '#permission_policies' do
        allow(Checkpoint::DB::Permit).to receive(:where).with(credential_token: 'permission:any').and_return(permits)
        expect(described_class.permission_policies(:any)).to eq policies
      end

      it '#resource_policies' do
        entity
        token
        allow(Checkpoint::DB::Permit).to receive(:where).with(resource_token: token).and_return(permits)
        expect(described_class.resource_policies(entity)).to eq policies
      end
    end
  end

  context 'Instance' do
    subject(:policy) { described_class.new }

    it 'invalid attributes' do
      expect(policy.valid?).to be false
      policy.set(invalid_attributes)
      expect(policy.valid?).to be false
      expect(policy.persisted?).to be false
      policy.save
      expect(policy.persisted?).to be false
      expect { policy.reload }.to raise_error(Sequel::NoExistingObject)
      expect(policy.persisted?).to be false
    end

    it 'valid attributes' do
      expect(policy.valid?).to be false
      policy.set(valid_attributes)
      expect(policy.valid?).to be true
      expect(policy.persisted?).to be false
      policy.save
      expect(policy.persisted?).to be true
      policy.reload
      expect(policy.persisted?).to be true
    end

    describe '#update?' do
      subject { policy.update? }

      it { is_expected.to be false }
    end

    describe '#destroy?' do
      subject { policy.destroy? }

      it { is_expected.to be true }
    end

    describe '#agent' do
      subject { policy.agent }

      it { is_expected.to be_an_instance_of(Entity) }
    end

    describe '#resource' do
      subject { policy.resource }

      it { is_expected.to be_an_instance_of(Entity) }
    end
  end
end
