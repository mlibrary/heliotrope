# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolicyAgent do
  let(:policy_agent) { described_class.new(agent_class, agent) }
  let(:agent_class) { nil }
  let(:agent) { nil }

  describe '#agent_type' do
    subject { policy_agent.agent_type }

    it { expect { subject }.to raise_error(NoMethodError) }

    context 'User' do
      let(:agent_class) { User }

      it { is_expected.to eq('user') }
    end
  end

  describe '#agent_id' do
    subject { policy_agent.agent_id }

    it { expect { subject }.to raise_error(NoMethodError) }

    context 'new' do
      let(:agent) { User.new }

      it { is_expected.to be nil }
    end

    context 'create' do
      let(:agent) { create(:user) }

      it { is_expected.to eq(agent.id) }
    end
  end
end
