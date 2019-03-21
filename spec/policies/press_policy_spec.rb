# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressPolicy do
  subject(:press_policy) { described_class.new(actor, press) }

  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:press) { double('press', subdomain: subdomain, agent_type: 'press_type', agent_id: 'press_id') }
  let(:subdomain) { 'subdomain' }
  let(:platform_admin) { false }

  before do
    allow(Sighrax).to receive(:platform_admin?).with(actor).and_return(platform_admin)
  end

  describe '#interval_download?' do
    subject { press_policy.interval_download? }

    it { is_expected.to be false }

    context 'heb' do
      let(:subdomain) { 'heb' }

      it { is_expected.to be true }
    end

    context 'platform_admin?' do
      let(:platform_admin) { true }

      it { is_expected.to be true }
    end
  end
end
