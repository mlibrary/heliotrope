# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionService do
  let(:permission_service) { described_class.new }

  describe 'checkpoint permits table' do
    it do
      described_class.database_initialize!
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

  describe '#agent' do
    subject { permission_service.agent(agent_type, agent_id) }

    let(:agent_type) { 'agent_type' }
    let(:agent_id) { 'agent_id' }

    it { expect { subject }.to raise_error(ArgumentError) }

    context 'valid arguments' do
      before do
        allow(ValidationService).to receive(:valid_agent_type?).with(agent_type).and_return(true)
        allow(ValidationService).to receive(:valid_agent?).with(agent_type, agent_id).and_return(true)
      end

      it 'is expected' do
        expect(subject).to be_an_instance_of(OpenStruct)
        expect(subject.agent_type).to eq agent_type
        expect(subject.agent_id).to eq agent_id
      end
    end

    [%w[any any], %w[email any], %w[email wolverine@umich.edu]].each do |type, id|
      context "#{type}:#{id}" do
        let(:agent_type) { type }
        let(:agent_id) { id }

        it 'is expected' do
          expect(subject).to be_an_instance_of(OpenStruct)
          expect(subject.agent_type).to eq agent_type
          expect(subject.agent_id).to eq agent_id
        end
      end
    end

    [Individual, Institution].each do |klass|
      context klass.to_s do
        let(:agent_type) { klass.to_s }

        context 'any' do
          let(:agent_id) { 'any' }

          it 'is expected' do
            expect(subject).to be_an_instance_of(OpenStruct)
            expect(subject.agent_type).to eq agent_type
            expect(subject.agent_id).to eq agent_id
          end
        end

        context 'instance' do
          let(:agent_id) { 1 }
          let(:instance) { klass.new(id: agent_id) }

          before { allow(klass).to receive(:find).with(agent_id).and_return(instance) }

          it 'is expected' do
            expect(subject).to be_an_instance_of(klass)
            expect(subject.id).to eq agent_id
          end
        end
      end
    end
  end

  describe '#permission' do
    subject { permission_service.permission(permission) }

    let(:permission) { 'permission' }

    it { expect { subject }.to raise_error(ArgumentError) }

    %w[any read].each do |permission|
      context permission.to_s do
        let(:permission) { permission }

        it 'is expected' do
          expect(subject).to be_an_instance_of(Checkpoint::Credential::Permission)
          expect(subject.id).to eq permission
        end
      end
    end
  end

  describe '#credential' do
    subject { permission_service.credential(credential_type, credential_id) }

    let(:credential_type) { 'credential_type' }
    let(:credential_id) { 'credential_id' }

    it { expect { subject }.to raise_error(ArgumentError) }

    context 'valid arguments' do
      before do
        allow(ValidationService).to receive(:valid_credential_type?).with(credential_type).and_return(true)
        allow(ValidationService).to receive(:valid_credential?).with(credential_type, credential_id).and_return(true)
      end

      it 'is expected' do
        expect(subject).to be_an_instance_of(OpenStruct)
        expect(subject.credential_type).to eq credential_type
        expect(subject.credential_id).to eq credential_id
      end
    end

    context 'any:any' do
      let(:credential_type) { :any }
      let(:credential_id) { :any }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'permission:any' do
      let(:credential_type) { :permission }
      let(:credential_id) { :any }

      it 'is expected' do
        expect(subject).to be_an_instance_of(Checkpoint::Credential::Permission)
        expect(subject.type).to eq credential_type.to_s
        expect(subject.id).to eq credential_id.to_s
      end
    end
  end

  describe '#resource' do
    subject { permission_service.resource(resource_type, resource_id) }

    let(:resource_type) { 'resource_type' }
    let(:resource_id) { 'resource_id' }

    it { expect { subject }.to raise_error(ArgumentError) }

    context 'valid arguments' do
      before do
        allow(ValidationService).to receive(:valid_resource_type?).with(resource_type).and_return(true)
        allow(ValidationService).to receive(:valid_resource?).with(resource_type, resource_id).and_return(true)
      end

      it 'is expected' do
        expect(subject).to be_an_instance_of(OpenStruct)
        expect(subject.resource_type).to eq resource_type
        expect(subject.resource_id).to eq resource_id
      end
    end

    [%w[any any], %w[noid any], %w[noid validnoid]].each do |type, id|
      context "#{type}:#{id}" do
        let(:resource_type) { type }
        let(:resource_id) { id }
        let(:noid_service) { double('noid_service', :valid? => true) } # rubocop:disable Style/HashSyntax

        before do
          allow(NoidService).to receive(:from_noid).with(resource_id).and_return(noid_service)
        end

        it 'is expected' do
          expect(subject).to be_an_instance_of(OpenStruct)
          expect(subject.resource_type).to eq resource_type
          expect(subject.resource_id).to eq resource_id
        end
      end
    end

    [Component, Product].each do |klass|
      context klass.to_s do
        let(:resource_type) { klass.to_s }

        context 'any' do
          let(:resource_id) { 'any' }

          it 'is expected' do
            expect(subject).to be_an_instance_of(OpenStruct)
            expect(subject.resource_type).to eq resource_type
            expect(subject.resource_id).to eq resource_id
          end
        end

        context 'instance' do
          let(:resource_id) { 1 }
          let(:instance) { klass.new(id: resource_id) }

          before { allow(klass).to receive(:find).with(resource_id).and_return(instance) }

          it 'is expected' do
            expect(subject).to be_an_instance_of(klass)
            expect(subject.id).to eq resource_id
          end
        end
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

  describe 'any access resource' do
    let(:agent_type) { :any }
    let(:agent_id) { :any }
    let(:resource_type) { :any }
    let(:resource_id) { :any }

    it do
      expect(permission_service.any_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be false
      permission_service.permit_any_access_resource(agent_type, agent_id, resource_type, resource_id)
      permission_service.permit_any_access_resource(agent_type, agent_id, resource_type, resource_id)
      expect(permission_service.any_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be true
      permission_service.revoke_any_access_resource(agent_type, agent_id, resource_type, resource_id)
      expect(permission_service.any_access_resource?(agent_type, agent_id, resource_type, resource_id)).to be false
    end
  end
end
