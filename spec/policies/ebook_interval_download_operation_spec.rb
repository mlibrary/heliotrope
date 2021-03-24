# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookIntervalDownloadOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, ebook) }
    let(:actor) { Anonymous.new({}) }
    let(:ebook) { instance_double(Sighrax::Ebook, 'ebook', publisher: publisher) }
    let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', interval?: interval) }
    let(:interval) { false }
    let(:licensed_for_download) { false }

    before do
      allow(policy).to receive(:licensed_for?).with(:download).and_return licensed_for_download
    end

    it { is_expected.to be false }

    context 'when licensed for download' do
      let(:licensed_for_download) { true }

      it { is_expected.to be false }

      context 'when publisher interval' do
        let(:interval) { true }

        it { is_expected.to be true }
      end
    end
  end
end
