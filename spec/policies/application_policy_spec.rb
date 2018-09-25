# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject(:application_policy) { described_class.new(current_user, resource_class, resource) }

  let(:current_user) { nil }
  let(:resource_class) { nil }
  let(:resource) { nil }

  it { expect(subject.send(:authority)).to be Services.checkpoint }
  it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
  it { expect { subject.authorize!(:action?) }.to raise_error(NotAuthorizedError) }

  context 'user' do
    let(:current_user) { double('current_user', id: 'current_user_id', identity: {}, platform_admin?: platform_admin) }
    let(:platform_admin) { false }

    it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
    it { expect { subject.authorize!(:action?) }.to raise_error(NotAuthorizedError) }

    context 'platform admin' do
      let(:platform_admin) { true }

      it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
      it { expect { subject.authorize!(:action?) }.not_to raise_error }
    end

    context 'checkpoint' do
      let(:checkpoint) { double('checkpoint') }
      let(:policy_agent) { double('policy agent', entity: agent_entity) }
      let(:agent_entity) { double('agent entity') }
      let(:policy_resource) { double('policy resource', entity: resource_entity) }
      let(:resource_entity) { double('resource entity') }

      before do
        allow(Services).to receive(:checkpoint).and_return(checkpoint)
        allow(PolicyAgent).to receive(:new).with(User, current_user).and_return(policy_agent)
        allow(PolicyResource).to receive(:new).with(resource_class, resource).and_return(policy_resource)
        allow(checkpoint).to receive(:permits?).with(agent_entity, :action, resource_entity).and_return(permit)
      end

      context 'unauthorized' do
        let(:permit) { false }

        it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
        it { expect { subject.authorize!(:action?) }.to raise_error(NotAuthorizedError) }
      end

      context 'authorized' do
        let(:permit) { true }

        it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
        it { expect { subject.authorize!(:action?) }.not_to raise_error }
      end
    end
  end
end
