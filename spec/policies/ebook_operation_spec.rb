# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookOperation do
  let(:policy) { described_class.new(actor, ebook) }
  let(:actor) { Anonymous.new({}) }
  let(:ebook) { instance_double(Sighrax::Ebook, 'ebook') }

  describe '#licensed_for?' do
    subject { policy.send(:licensed_for?, entitlement) }

    let(:entitlement) { :entitlement }
    let(:checkpoint) { double('checkpoint') }
    let(:license) { create(:license) }

    before do
      allow(Services).to receive(:checkpoint).and_return checkpoint
      allow(checkpoint).to receive(:licenses_for).with(actor, ebook).and_return [license]
    end

    it { is_expected.to be false }

    context 'when license entitlement' do
      before { allow(license).to receive(:allows?).with(entitlement).and_return true }

      it { is_expected.to be true }
    end
  end
end
