# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PDFEbookPresenter do
  subject(:presenter) { described_class.new(pdf_ebook) }

  let(:pdf_ebook) { instance_double(PDFEbook::Publication, 'pdf_ebook', id: 'id', intervals: intervals) }
  let(:intervals) { [] }

  describe '#id' do
    subject { presenter.id }

    it { is_expected.to eq(pdf_ebook.id) }
  end

  describe '#multi_rendition?' do
    subject { presenter.multi_rendition? }

    it { is_expected.to be false }
  end

  describe '#intervals?' do
    context "with a valid/not broken pdf" do
      subject { presenter.intervals? }

      it { is_expected.to be false }

      context 'with actual intervals' do
        let(:intervals) { [interval] }
        let(:interval) { double('interval') }

        it { is_expected.to be true }
      end
    end

    context "with a broken pdf" do
      subject { presenter.intervals? }

      let(:pdf_ebook) { PDFEbook::PublicationNullObject.send(:new) }

      it { is_expected.to be false }
    end
  end

  describe '#intervals' do
    subject { presenter.intervals.first }

    it { is_expected.to be_nil }

    context 'intervals' do
      before do
        EbookTableOfContentsCache.create(noid: pdf_ebook.id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0", download?: false }].to_json)
      end

      it { is_expected.to be_an_instance_of(EBookIntervalPresenter) }
    end
  end
end
