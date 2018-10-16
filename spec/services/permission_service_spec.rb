# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionService do
  let(:permission_service) { described_class.new }

  describe '#valid_email?' do
    subject { permission_service.valid_email?(email) }

    let(:email) { nil }

    it { is_expected.to be false }

    context 'valid' do
      let(:email) { 'wolverine@umich.edu' }

      it { is_expected.to be true }
    end
  end

  describe '#valid_agent?' do
    subject { permission_service.valid_agent?(agent_type, agent_id) }

    let(:agent_type) { nil }
    let(:agent_id) { nil }

    it { is_expected.to be false }

    context 'email' do
      let(:agent_type) { :email }

      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { 'wolverine@umich.edu' }

        it { is_expected.to be true }
      end
    end

    context 'institution' do
      let(:agent_type) { :institution }

      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { double('agent_id') }
        let(:institution) { double('institution') }

        before { allow(Institution).to receive(:find_by).with(identifier: agent_id.to_s).and_return(institution) }

        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_noid?' do
    subject { permission_service.valid_noid?(noid) }

    let(:noid) { nil }

    it { is_expected.to be false }

    context 'valid' do
      let(:noid) { 'validnoid' }

      it { is_expected.to be true }
    end
  end

  describe '#valid_resource?' do
    subject { permission_service.valid_resource?(resource_type, resource_id) }

    let(:resource_type) { nil }
    let(:resource_id) { nil }

    it { is_expected.to be false }

    context 'noid' do
      let(:resource_type) { :noid }

      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { 'validnoid' }

        it { is_expected.to be true }
      end
    end

    context 'product' do
      let(:resource_type) { :product }

      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { double('resource_id') }
        let(:product) { double('product') }

        before { allow(Product).to receive(:find_by).with(identifier: resource_id.to_s).and_return(product) }

        it { is_expected.to be true }
      end
    end
  end

  describe 'open access' do
    it do
      expect(permission_service.open_access?).to be false
      permission_service.permit_open_access
      permission_service.permit_open_access
      expect(permission_service.open_access?).to be true
      permission_service.revoke_open_access
      expect(permission_service.open_access?).to be false
    end
  end

  describe 'open access resource' do
    let(:resource_type) { :noid }
    let(:resource_id) { 'validnoid' }

    it do
      expect(permission_service.open_access_resource?(resource_type, resource_id)).to be false
      permission_service.permit_open_access_resource(resource_type, resource_id)
      permission_service.permit_open_access_resource(resource_type, resource_id)
      expect(permission_service.open_access_resource?(resource_type, resource_id)).to be true
      permission_service.revoke_open_access_resource(resource_type, resource_id)
      expect(permission_service.open_access_resource?(resource_type, resource_id)).to be false
    end
  end

  describe 'read access resource' do
    let(:agent_type) { :email }
    let(:agent_id) { 'wolverine@umich.edu' }
    let(:resource_type) { :noid }
    let(:resource_id) { 'validnoid' }

    it do
      expect(permission_service.read_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be false
      permission_service.permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
      permission_service.permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
      expect(permission_service.read_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be true
      permission_service.revoke_read_access_resource(agent_type, agent_id, resource_type, resource_id)
      expect(permission_service.read_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be false
    end
  end
end
