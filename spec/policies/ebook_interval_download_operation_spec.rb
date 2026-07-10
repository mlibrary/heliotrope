# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EbookIntervalDownloadOperation do
  describe '#allowed?' do
    subject { policy.allowed? }

    let(:policy) { described_class.new(actor, ebook) }
    let(:actor) { Anonymous.new({}) }
    let(:ebook_class) { Sighrax::PdfEbook }
    let(:ebook) do
      instance_double(ebook_class, 'ebook', publisher: publisher).tap do |dbl|
        # `instance_double` doesn't preserve real ancestry, so stub `is_a?`
        # to match the ebook type this double is standing in for.
        allow(dbl).to receive(:is_a?) { |klass| ebook_class <= klass }
      end
    end
    let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', epub_chapter_downloads?: epub_chapter_downloads, pdf_chapter_downloads?: pdf_chapter_downloads) }
    let(:epub_chapter_downloads) { false }
    let(:pdf_chapter_downloads) { false }
    let(:can_update) { false }
    let(:accessible_online) { false }
    let(:unrestricted) { false }
    let(:licensed_for_download) { false }

    before do
      allow(policy).to receive(:can?).with(:update).and_return can_update
      allow(policy).to receive(:accessible_online?).and_return accessible_online
      allow(policy).to receive(:unrestricted?).and_return unrestricted
      allow(policy).to receive(:licensed_for?).with(:download).and_return licensed_for_download
    end

    it { is_expected.to be false }

    context 'when publisher allows chapter downloads for this ebook type' do
      let(:pdf_chapter_downloads) { true }

      it { is_expected.to be false }

      # You *can* download PDF chapters from the Monograph catalog page just because you're an editor.
      # This is less of an issue than allowing same for the full-ebook downloads because there's no metadata involved.
      # In other words, `allow_download` on the ebook FileSet is not involved. Only the press setting and...
      # draft/public status matter here.
      context 'when can edit' do
        let(:can_update) { true }

        it { is_expected.to be true }
      end

      context 'when online access' do
        let(:accessible_online) { true }

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
    end

    context 'when can edit' do
      let(:can_update) { true }

      it { is_expected.to be false }
    end

    context 'when online access' do
      let(:accessible_online) { true }

      it { is_expected.to be false }

      context 'when unrestricted' do
        let(:unrestricted) { true }

        it { is_expected.to be false }
      end

      context 'when licensed for download' do
        let(:licensed_for_download) { true }

        it { is_expected.to be false }
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

    context 'when the ebook is an EpubEbook' do
      let(:ebook_class) { Sighrax::EpubEbook }

      it 'is not allowed when the publisher disallows epub chapter downloads' do
        expect(subject).to be false
      end

      # Sanity check: the pdf setting must not affect epub ebooks.
      context 'when only pdf_chapter_downloads is enabled' do
        let(:pdf_chapter_downloads) { true }
        let(:accessible_online) { true }
        let(:unrestricted) { true }

        it { is_expected.to be false }
      end

      context 'when publisher allows epub chapter downloads' do
        let(:epub_chapter_downloads) { true }

        it { is_expected.to be false }

        context 'when can edit' do
          let(:can_update) { true }

          it { is_expected.to be true }
        end

        context 'when online access and unrestricted' do
          let(:accessible_online) { true }
          let(:unrestricted) { true }

          it { is_expected.to be true }
        end

        context 'when online access and licensed for download' do
          let(:accessible_online) { true }
          let(:licensed_for_download) { true }

          it { is_expected.to be true }
        end
      end
    end
  end
end
