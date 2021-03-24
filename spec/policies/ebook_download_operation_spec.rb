# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookDownloadOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, ebook) }
    let(:actor) { Anonymous.new({}) }
    let(:ebook) { instance_double(Sighrax::Ebook, 'ebook') }
    let(:accessible_offline) { false }
    let(:unrestricted) { false }
    let(:licensed_for_download) { false }

    before do
      allow(policy).to receive(:accessible_offline?).and_return accessible_offline
      allow(policy).to receive(:unrestricted?).and_return unrestricted
      allow(policy).to receive(:licensed_for?).with(:download).and_return licensed_for_download
    end

    it { is_expected.to be false }

    context 'when accessible offline' do
      let(:accessible_offline) { true }

      it { is_expected.to be false }

      context 'when unrestricted' do
        let(:unrestricted) { true }

        it { is_expected.to be true }
      end

      context 'when licensed for download' do
        let(:licensed_for_download) { true }

        it { is_expected.to be true }
      end
    end

    context 'when unrestricted' do
      let(:unrestricted) { true }

      it { is_expected.to be false }
    end

    context 'when licensed for download' do
      let(:licensed_for_download) { true }

      it { is_expected.to be false }
    end
  end
end
