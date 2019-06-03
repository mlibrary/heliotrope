# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressPolicy do
  subject(:press_policy) { described_class.new(actor, press) }

  let(:actor) { instance_double(Anonymous, 'actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:press) { instance_double(Press, 'press', subdomain: subdomain, agent_type: 'press_type', agent_id: 'press_id', watermark: watermark) }
  let(:subdomain) { 'subdomain' }
  let(:watermark) { false }
  let(:platform_admin) { false }

  before do
    allow(Sighrax).to receive(:platform_admin?).with(actor).and_return(platform_admin)
  end

  describe '#interval_read_button?' do
    subject { press_policy.interval_read_button?(interval) }

    let(:interval) { instance_double(EPub::Interval, 'interval', downloadable?: downloadable) }
    let(:downloadable) { 'downloadable' }

    it { is_expected.to be downloadable }
  end

  describe '#interval_download_button?' do
    subject { press_policy.interval_download_button?(interval) }

    let(:interval) { instance_double(EPub::Interval, 'interval', downloadable?: downloadable) }
    let(:downloadable) { false }

    it { is_expected.to be false }

    context 'downloadable' do
      let(:downloadable) { true }
      let(:interval_download) { 'interval_download' }

      before { allow(press_policy).to receive(:interval_download?).and_return(interval_download) }

      it { is_expected.to be interval_download }
    end
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

  describe '#watermark_download?' do
    subject { press_policy.watermark_download? }

    it { is_expected.to be false }

    context 'watermark' do
      let(:watermark) { true }

      it { is_expected.to be true }
    end
  end
end
