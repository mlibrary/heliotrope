# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookReaderOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, ebook) }
    let(:actor) { Anonymous.new({}) }
    let(:ebook) { instance_double(Sighrax::Ebook, 'ebook') }
    let(:licensed_for_reader) { false }

    before do
      allow(policy).to receive(:licensed_for?).with(:reader).and_return licensed_for_reader
    end

    it { is_expected.to be false }

    context 'when licensed for reader' do
      let(:licensed_for_reader) { true }

      it { is_expected.to be true }
    end
  end
end
