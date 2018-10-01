# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(current_user, e_pub) }

  let(:current_user) { double('current user', id: 'current_user_id', platform_admin?: false) }
  let(:e_pub) { double('e pub', id: 'e_pub_id') }

  it { is_expected.to be_a_kind_of(ApplicationPolicy) }

  context 'checkpoint' do
    let(:checkpoint) { double('checkpoint') }
    let(:policy_agent) { double('policy agent', entity: agent_entity) }
    let(:agent_entity) { double('agent entity') }
    let(:policy_resource) { double('policy resource', entity: resource_entity) }
    let(:resource_entity) { double('resource entity') }

    before do
      allow(Services).to receive(:checkpoint).and_return(checkpoint)
      allow(checkpoint).to receive(:permits?).with(agent_entity, :action, resource_entity).and_return(permit)
      allow(PolicyAgent).to receive(:new).with(User, current_user).and_return(policy_agent)
      allow(PolicyResource).to receive(:new).with(EPub, e_pub).and_return(policy_resource)
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
