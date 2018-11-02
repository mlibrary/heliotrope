# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(current_user, current_institutions, e_pub_id) }

  let(:current_user) { double('current_user', email: nil) }
  let(:current_institutions) { nil }
  let(:e_pub_id) { nil }
  let(:action) { :action }
  let(:checkpoint) { double('checkpoint') }
  let(:permits) { false }

  before do
    allow(Services).to receive(:checkpoint).and_return(checkpoint)
    allow(checkpoint).to receive(:permits?).with({ user: current_user, institutions: current_institutions }, action, noid: e_pub_id).and_return(permits)
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

    before { allow(checkpoint).to receive(:permits?).with({ user: current_user, institutions: current_institutions }, :read, noid: e_pub_id).and_return(permits) }

    it { is_expected.to be false }

    context 'read permitted' do
      let(:permits) { true }

      it { is_expected.to be true }
    end
  end
end
