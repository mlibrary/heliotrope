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

    context 'individual' do
      let(:agent_type) { :individual }

      it { expect(permission_service.valid_agent_type?(agent_type)).to be true }
      it { expect(permission_service.valid_individual?(agent_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:agent_id) { double('agent_id') }
        let(:individual) { double('individual') }

        before { allow(Individual).to receive(:find).with(agent_id).and_return(individual) }

        it { expect(permission_service.valid_individual?(agent_id)).to be true }
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

        before { allow(Institution).to receive(:find).with(agent_id).and_return(institution) }

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

    context 'component' do
      let(:resource_type) { :component }

      it { expect(permission_service.valid_resource_type?(resource_type)).to be true }
      it { expect(permission_service.valid_component?(resource_id)).to be false }
      it { is_expected.to be false }

      context 'valid' do
        let(:resource_id) { double('resource_id') }
        let(:component) { double('component') }

        before { allow(Component).to receive(:find).with(resource_id).and_return(component) }

        it { expect(permission_service.valid_component?(resource_id)).to be true }
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

        before { allow(Product).to receive(:find).with(resource_id).and_return(product) }

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
    let(:resource_type) { :any }
    let(:resource_id) { :any }

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
    let(:agent_type) { :any }
    let(:agent_id) { :any }
    let(:resource_type) { :any }
    let(:resource_id) { :any }

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
