# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authority do
  let(:checkpoint) { double('checkpoint') }

  before do
    allow(Services).to receive(:checkpoint).and_return(checkpoint)
  end

  describe '#agent_grants?' do
    subject { described_class.agent_grants?(agent) }

    let(:agent) { double('agent') }
    let(:resources) { [] }

    before do
      allow(checkpoint).to receive(:which).with(agent, :read).and_return(resources)
    end

    it { is_expected.to be false }

    context 'resource' do
      let(:resources) { [resource] }
      let(:resource) { double('resource') }

      it { is_expected.to be true }
    end
  end

  describe '#agent' do
    subject { described_class.agent(agent_type, agent_id) }

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

    [%w[any any]].each do |type, id|
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

    context 'Guest' do
      let(:agent_type) { Guest.to_s.to_sym }

      context 'any' do
        let(:agent_id) { 'any' }

        it 'is expected' do
          expect(subject).to be_an_instance_of(OpenStruct)
          expect(subject.agent_type).to eq agent_type
          expect(subject.agent_id).to eq agent_id
        end
      end

      context 'instance' do
        let(:agent_id) { 'wolverine@umich.edu' }
        let(:instance) { User.guest(user_key: agent_id) }

        before { allow(User).to receive(:guest).with(user_key: agent_id).and_return(instance) }

        it 'is expected' do
          expect(subject).to be_an_instance_of(Guest)
          expect(subject.agent_type).to eq agent_type
          expect(subject.agent_id).to eq agent_id
        end
      end
    end

    [Individual, Institution, User].each do |klass|
      context klass.to_s do
        let(:agent_type) { klass.to_s.to_sym }

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
            expect(subject.agent_type).to eq agent_type
            expect(subject.agent_id).to eq agent_id
          end
        end
      end
    end
  end

  describe '#credential_grants?' do
    subject { described_class.credential_grants?(credential) }

    let(:credential) { double('credential') }
    let(:agents) { [] }

    before do
      allow(checkpoint).to receive(:who).with(credential, Checkpoint::Resource.all).and_return(agents)
    end

    it { is_expected.to be false }

    context 'resource' do
      let(:agents) { [agent] }
      let(:agent) { double('agent') }

      it { is_expected.to be true }
    end
  end

  describe '#permission' do
    subject { described_class.permission(permission) }

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
    subject { described_class.credential(credential_type, credential_id) }

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

  describe '#resource_grants?' do
    subject { described_class.resource_grants?(resource) }

    let(:resource) { double('resource') }
    let(:agents) { [] }

    before do
      allow(checkpoint).to receive(:who).with(:read, resource).and_return(agents)
    end

    it { is_expected.to be false }

    context 'resource' do
      let(:agents) { [agent] }
      let(:agent) { double('agent') }

      it { is_expected.to be true }
    end
  end

  describe '#resource' do
    subject { described_class.resource(resource_type, resource_id) }

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

    [%w[any any]].each do |type, id|
      context "#{type}:#{id}" do
        let(:resource_type) { type }
        let(:resource_id) { id }

        it 'is expected' do
          expect(subject).to be_an_instance_of(OpenStruct)
          expect(subject.resource_type).to eq resource_type
          expect(subject.resource_id).to eq resource_id
        end
      end
    end

    [Sighrax::ElectronicPublication].each do |klass|
      context klass.to_s do
        let(:resource_type) { klass.to_s.sub('Sighrax::', '').to_sym }

        context 'any' do
          let(:resource_id) { 'any' }

          it 'is expected' do
            expect(subject).to be_an_instance_of(OpenStruct)
            expect(subject.resource_type).to eq resource_type
            expect(subject.resource_id).to eq resource_id
          end
        end

        context 'instance' do
          let(:resource_id) { 'validnoid' }
          let(:instance) { klass.send(:new, resource_id, nil) }

          before { allow(Sighrax).to receive(:factory).with(resource_id).and_return(instance) }

          it 'is expected' do
            expect(subject).to be_an_instance_of(klass)
            expect(subject.resource_type).to eq resource_type
            expect(subject.resource_id).to eq resource_id
          end
        end
      end
    end

    [Component, Product].each do |klass|
      context klass.to_s do
        let(:resource_type) { klass.to_s.to_sym }

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
            expect(subject.resource_type).to eq resource_type
            expect(subject.resource_id).to eq resource_id
          end
        end
      end
    end
  end
end
