# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceDownloadOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, resource) }
    let(:actor) { Anonymous.new({}) }
    let(:resource) { instance_double(Sighrax::Resource, 'resource', downloadable?: downloadable, published?: published, tombstone?: tombstone, allow_download?: allow_download) }
    let(:downloadable) { false }
    let(:published) { false }
    let(:tombstone) { false }
    let(:allow_download) { false }
    let(:can_edit) { false }

    before do
      allow(policy).to receive(:can?).with(:edit).and_return can_edit
    end

    it { is_expected.to be false }

    context 'when resource is an ebook' do
      let(:ebook_download_op) { instance_double(EbookDownloadOperation, 'ebook_download_op', allowed?: allowed) }
      let(:allowed) { double('boolean') }

      before do
        allow(resource).to receive(:is_a?).with(Sighrax::Ebook).and_return true
        allow(EbookDownloadOperation).to receive(:new).with(actor, resource).and_return ebook_download_op
      end

      it { is_expected.to be allowed }
    end

    context 'when downloadable' do
      let(:downloadable) { true }

      it { is_expected.to be false }

      context 'when can edit' do
        let(:can_edit) { true }

        it { is_expected.to be true }
      end

      context 'when published' do
        let(:published) { true }

        it { is_expected.to be false }
      end

      context 'when tombstone' do
        let(:tombstone) { true }

        it { is_expected.to be false }
      end

      context 'when allow download' do
        let(:allow_download) { true }

        it { is_expected.to be false }
      end

      context 'when published and allow download' do
        let(:published) { true }
        let(:allow_download) { true }

        it { is_expected.to be true }

        context 'when tombstone' do
          let(:tombstone) { true }

          it { is_expected.to be false }
        end
      end
    end
  end
end
