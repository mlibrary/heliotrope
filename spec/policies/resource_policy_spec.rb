# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourcePolicy do
  subject(:resource_policy) { described_class.new(actor, target) }

  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:target) { double('target', agent_type: 'target_type', agent_id: 'target_id') }

  %i[show? create? update? destroy? edit?].each do |action|
    describe action.to_s do
      subject { resource_policy.send(action) }

      before { allow(actor).to receive(:is_a?).with(User).and_return(false) }

      it { is_expected.to be false }

      context 'is_a?(User)' do
        before do
          allow(actor).to receive(:is_a?).with(User).and_return(true)
          allow(actor).to receive(:platform_admin?).and_return(false)
        end

        it { is_expected.to be false }

        context 'platform_admin?' do
          before { allow(actor).to receive(:platform_admin?).and_return(true) }

          it { is_expected.to be true }
        end
      end
    end
  end
end
