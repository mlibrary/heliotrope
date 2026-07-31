# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PDFEbookPresenter do
  subject(:presenter) { described_class.new(id) }

  let(:id) { '999999999' }

  describe '#id' do
    it "returns the id" do
      expect(described_class.new(id).id).to eq id
    end
  end

  describe '#intervals?' do
    subject { presenter.intervals? }

    it { is_expected.to be false }

    context 'with a cached ToC' do
      before do
        EbookTableOfContentsCache.create(noid: id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0", download?: false }].to_json)
      end

      it { is_expected.to be true }
    end
  end

  describe '#intervals' do
    subject { presenter.intervals }

    context 'with no cached ToC' do
      # The on-the-fly PDF-parsing fallback has been removed in favor of a single
      # source of truth (the ToC cache built by UnpackJob#cache_pdf_toc), so a
      # missing cache is now surfaced as nil.
      it { is_expected.to be_nil }
    end

    context 'with a cached ToC' do
      before do
        EbookTableOfContentsCache.create(noid: id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0", download?: false }].to_json)
      end

      it "returns the intervals" do
        expect(presenter.intervals.first).to be_an_instance_of(EBookIntervalPresenter)
        expect(presenter.intervals.first.cfi).to eq "/6/2[Chapter01]!/4/1:0"
      end
    end
  end
end
