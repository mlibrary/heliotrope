# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPresenter do
  subject(:presenter) { described_class.new(epub) }

  let(:epub) { instance_double(EPub::Publication, 'epub', id: 'id', rendition: rendition, multi_rendition?: multi_rendition) }
  let(:multi_rendition) { false }
  let(:rendition) { instance_double(EPub::Rendition, 'rendition', intervals: intervals) }
  let(:intervals) { [] }

  describe '#id' do
    subject { presenter.id }

    it { is_expected.to eq(epub.id) }
  end

  describe '#multi_rendition?' do
    subject { presenter.multi_rendition? }

    it { is_expected.to be false }

    context 'multi_rendition' do
      let(:multi_rendition) { true }

      it { is_expected.to be true }
    end
  end

  describe '#intervals?' do
    context "with a valid epub" do
      subject { presenter.intervals? }

      it { is_expected.to be false }

      context 'with a cached ToC' do
        before do
          EbookTableOfContentsCache.create(noid: epub.id, toc: [{ title: "A", level: 1, cfi: "/6/2[Chapter01]!/4/1:0", downloadable?: false }].to_json)
        end

        it { is_expected.to be true }
      end
    end

    context "with an invalid epub" do
      subject { presenter.intervals? }

      let(:epub) { EPub::PublicationNullObject.send(:new) }

      it { is_expected.to be false }
    end
  end

  describe '#intervals' do
    context 'with no cached ToC' do
      # The rendition-based fallback has been removed in favor of a single
      # source of truth (EpubChaptersService via UnpackJob#cache_epub_toc),
      # so a missing cache is now surfaced as nil.
      subject { presenter.intervals }

      it { is_expected.to be_nil }
    end

    context 'with a cached ToC' do
      subject { presenter.intervals.first }

      before do
        EbookTableOfContentsCache.create(noid: epub.id, toc: [{ title: "A", level: 1, cfi: "/6/2[Chapter01]!/4/1:0", downloadable?: false }].to_json)
      end

      it { is_expected.to be_an_instance_of(EBookIntervalPresenter) }
    end
  end
end
