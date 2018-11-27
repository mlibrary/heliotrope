# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject(:e_pub_policy) { described_class.new(actor, target, share) }

  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:target) { double('target', agent_type: 'target_type', agent_id: 'target_id') }
  let(:share) { false }
  let(:show) { false }
  let(:hyrax_can) { false }
  let(:published) { false }
  let(:restricted) { false }
  let(:checkpoint) { double('checkpoint') }

  before do
    allow(actor).to receive(:is_a?).with(User).and_return(false)
    allow(actor).to receive(:platform_admin?).and_return(false)
    allow(Sighrax).to receive(:hyrax_can?).with(actor, :read, target).and_return(hyrax_can)
    allow(Sighrax).to receive(:published?).with(target).and_return(published)
    allow(Sighrax).to receive(:restricted?).with(target).and_return(restricted)
    allow(Services).to receive(:checkpoint).and_return(checkpoint)
  end

  describe '#show?' do
    subject { e_pub_policy.show? }

    let(:permits) { false }

    before { allow(checkpoint).to receive(:permits?).with(actor, :read, target).and_return(permits) }

    it { is_expected.to be false }

    context 'super' do
      before do
        allow(actor).to receive(:is_a?).with(User).and_return(true)
        allow(actor).to receive(:platform_admin?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'hyrax_can?' do
      let(:hyrax_can) { true }

      it { is_expected.to be true }
    end

    context 'published?' do
      let(:published) { true }

      it { is_expected.to be true }

      context 'restricted?' do
        let(:restricted) { true }

        it { is_expected.to be false }

        context 'share' do
          let(:share) { true }

          it { is_expected.to be true }
        end

        context 'action_permitted?' do
          let(:permits) { true }

          it { is_expected.to be true }
        end
      end
    end
  end
end
