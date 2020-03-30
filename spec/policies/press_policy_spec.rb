# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressPolicy do
  subject(:press_policy) { described_class.new(actor, press) }

  let(:actor) { instance_double(Anonymous, 'actor', agent_type: 'actor_type', agent_id: 'actor_id') }
  let(:press) { instance_double(Press, 'press', subdomain: subdomain, agent_type: 'press_type', agent_id: 'press_id', watermark: watermark) }
  let(:subdomain) { 'subdomain' }
  let(:watermark) { false }
  let(:platform_admin) { false }

  describe '#allows_interval_download?' do
    subject { press_policy.allows_interval_download? }

    it { is_expected.to be false }

    context 'blah' do
      let(:subdomain) { 'blah' }

      it { is_expected.to be false }
    end

    context 'heb' do
      let(:subdomain) { 'heb' }

      it { is_expected.to be true }
    end

    context 'heliotrope' do
      let(:subdomain) { 'heliotrope' }

      it { is_expected.to be true }
    end

    context 'barpublishing' do
      let(:subdomain) { 'barpublishing' }

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
