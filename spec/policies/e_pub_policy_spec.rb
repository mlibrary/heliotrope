# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(actor, target) }

  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id', individual: individual, institutions: institutions) }
  let(:individual) {}
  let(:institutions) { [] }
  let(:target) { double('target', agent_type: 'target_type', agent_id: 'target_id', component: component, products: products) }
  let(:component) {}
  let(:products) { [] }
  let(:action) { :action }
  let(:checkpoint) { double('checkpoint') }
  let(:permits) { false }

  before do
    allow(Services).to receive(:checkpoint).and_return(checkpoint)
    allow(checkpoint).to receive(:permits?).with(actor, action, target).and_return(permits)
  end

  describe '#authorize!' do
    subject { e_pub_policy.authorize!(action) }

    it ':action denied' do expect { subject }.to raise_error(NotAuthorizedError) end

    context 'permitted' do
      let(:permits) { true }

      it ':action permitted' do expect { subject }.not_to raise_error end

      context 'standard error' do
        before { allow_any_instance_of(Checkpoint::Query::ActionPermitted).to receive(:true?).and_raise(StandardError) }

        it ':action denied' do expect { subject }.to raise_error(NotAuthorizedError) end
      end
    end
  end

  describe '#show?' do
    subject { e_pub_policy.show? }

    before { allow(checkpoint).to receive(:permits?).with(actor, :read, target).and_return(permits) }

    it { is_expected.to be false }

    context 'read permitted' do
      let(:permits) { true }

      it { is_expected.to be true }
    end
  end
end
