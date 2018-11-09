# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grant, type: :model do
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

    context 'grants' do
      let(:entity) { double('entity', id: 'id') }
      let(:token) { "#{entity.class}:#{entity.id}" }
      let(:permit) { double('permit') }
      let(:permits) { [permit] }
      let(:grant) { double('grant') }
      let(:grants) { [grant] }

      before { allow(described_class).to receive(:new).with(permit).and_return(grant) }

      it '#agent_grants' do
        entity
        token
        allow(Checkpoint::DB::Permit).to receive(:where).with(agent_token: token).and_return(permits)
        expect(described_class.agent_grants(entity)).to eq grants
      end

      it '#permission_grants' do
        allow(Checkpoint::DB::Permit).to receive(:where).with(credential_token: 'permission:any').and_return(permits)
        expect(described_class.permission_grants(:any)).to eq grants
      end

      it '#resource_grants' do
        entity
        token
        allow(Checkpoint::DB::Permit).to receive(:where).with(resource_token: token).and_return(permits)
        expect(described_class.resource_grants(entity)).to eq grants
      end
    end
  end

  context 'Instance' do
    subject(:grant) { described_class.new }

    it 'invalid attributes' do
      expect(grant.valid?).to be false
      grant.set(invalid_attributes)
      expect(grant.valid?).to be false
      expect(grant.persisted?).to be false
      grant.save
      expect(grant.persisted?).to be false
      expect { grant.reload }.to raise_error(Sequel::NoExistingObject)
      expect(grant.persisted?).to be false
    end

    it 'valid attributes' do
      expect(grant.valid?).to be false
      grant.set(valid_attributes)
      expect(grant.valid?).to be true
      expect(grant.persisted?).to be false
      grant.save
      expect(grant.persisted?).to be true
      grant.reload
      expect(grant.persisted?).to be true
    end

    describe '#update?' do
      subject { grant.update? }

      it { is_expected.to be false }
    end

    describe '#destroy?' do
      subject { grant.destroy? }

      it { is_expected.to be true }
    end
  end
end
