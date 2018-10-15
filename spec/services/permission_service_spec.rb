# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionService do
  let(:permission_service) { described_class.new }

  describe 'checkpoint permits table' do
    it do
      described_class.clear_permits_table
      expect(described_class.permits_table_empty?).to be true
      permission_service.permit_open_access
      expect(permission_service.open_access?).to be true
      expect(described_class.permits_table_empty?).to be false
      described_class.clear_permits_table
      expect(permission_service.open_access?).to be false
      expect(described_class.permits_table_empty?).to be true
    end
  end

  describe '#valid_agent?' do
    subject { permission_service.valid_agent?(agent_type, agent_id) }

    let(:agent_type) { nil }
    let(:agent_id) { nil }

    it { expect(permission_service.valid_agent_type?(agent_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:agent_type) { :any }

      it { expect(permission_service.valid_agent_type?(agent_type)).to be true }
      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { 'any' }

        it { is_expected.to be true }
      end
    end

    context 'email' do
      let(:agent_type) { :email }

      it { expect(permission_service.valid_agent_type?(agent_type)).to be true }
      it { expect(permission_service.valid_email?(agent_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { 'wolverine@umich.edu' }

        it { expect(permission_service.valid_email?(agent_id)).to be true }
        it { is_expected.to be true }
      end
    end

    context 'institution' do
      let(:agent_type) { :institution }

      it { expect(permission_service.valid_agent_type?(agent_type)).to be true }
      it { expect(permission_service.valid_institution?(agent_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { double('agent_id') }
        let(:institution) { double('institution') }

        before { allow(Institution).to receive(:find_by).with(identifier: agent_id.to_s).and_return(institution) }

        it { expect(permission_service.valid_institution?(agent_id)).to be true }
        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_credential?' do
    subject { permission_service.valid_credential?(credential_type, credential_id) }

    let(:credential_type) { nil }
    let(:credential_id) { nil }

    it { expect(permission_service.valid_credential_type?(credential_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:credential_type) { :any }

      it { expect(permission_service.valid_credential_type?(credential_type)).to be true }
      it { is_expected.to be false }

      context 'valid' do
        let(:credential_id) { 'any' }

        it { is_expected.to be true }
      end
    end

    context 'permission' do
      let(:credential_type) { :permission }

      it { expect(permission_service.valid_credential_type?(credential_type)).to be true }
      it { expect(permission_service.valid_permission?(credential_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:credential_id) { :read }

        it { expect(permission_service.valid_permission?(credential_id)).to be true }
        it { is_expected.to be true }
      end
    end
  end

  describe '#valid_resource?' do
    subject { permission_service.valid_resource?(resource_type, resource_id) }

    let(:resource_type) { nil }
    let(:resource_id) { nil }

    it { expect(permission_service.valid_resource_type?(resource_type)).to be false }
    it { is_expected.to be false }

    context 'any' do
      let(:resource_type) { :any }

      it { expect(permission_service.valid_resource_type?(resource_type)).to be true }
      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { 'any' }

        it { is_expected.to be true }
      end
    end

    context 'noid' do
      let(:resource_type) { :noid }

      it { expect(permission_service.valid_resource_type?(resource_type)).to be true }
      it { expect(permission_service.valid_noid?(resource_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { 'validnoid' }

        it { expect(permission_service.valid_noid?(resource_id)).to be true }
        it { is_expected.to be true }
      end
    end

    context 'product' do
      let(:resource_type) { :product }

      it { expect(permission_service.valid_resource_type?(resource_type)).to be true }
      it { expect(permission_service.valid_product?(resource_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { double('resource_id') }
        let(:product) { double('product') }

        before { allow(Product).to receive(:find_by).with(identifier: resource_id.to_s).and_return(product) }

        it { expect(permission_service.valid_product?(resource_id)).to be true }
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
