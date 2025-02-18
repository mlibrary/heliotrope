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

  describe '#multi_rendition?' do
    it "always returns false, pdfs don't have multiple renditions" do
      expect(described_class.new(id).multi_rendition?).to be false
    end
  end

  describe '#intervals?' do
    context "with a valid/not broken pdf" do
      context "with a EbookTableOfContentsCache cache" do
        before do
          EbookTableOfContentsCache.create(noid: id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0", download?: false }].to_json)
        end

        it "gets the intervals from the cache, returns true" do
          expect(described_class.new(id).intervals?).to be true
        end
      end

      context "without a EbookTableOfContentsCache cache" do
        let(:pdf_ebook) { instance_double(PDFEbook::Publication, 'pdf_ebook', id: 'id', intervals: intervals) }
        let(:intervals) { ['interval'] }
        before do
          allow(PDFEbook::Publication).to receive(:from_path_id).and_return(pdf_ebook)
        end

        it "parses the pdf for the intervals, returns true" do
          expect(described_class.new(id).intervals?).to be true
        end
      end
    end

    context "with a broken pdf" do
      subject { presenter.intervals? }

      let(:pdf_ebook) { PDFEbook::PublicationNullObject.send(:new) }

      it { is_expected.to be false }
    end
  end

  describe '#intervals' do
    context "with a valid/not broken pdf" do
      context "with a EbookTableOfContentsCache cache" do
        before do
          EbookTableOfContentsCache.create(noid: id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0", download?: false }].to_json)
        end

        it "returns the intervals" do
          expect(described_class.new(id).intervals.first).to be_an_instance_of(EBookIntervalPresenter)
          expect(described_class.new(id).intervals.first.cfi).to eq "/6/2[Chapter01]!/4/1:0"
        end
      end

      context "without a EbookTableOfContentsCache cache" do
        # When this happens, it's a problem. We know it's bad. We do not want to parse entire pdfs on the fly just to
        # get the table of contents. But it still happens sometimes. Sometimes a pdf has some kind of problem and the
        # ToC doesn't get cached. Instead of an error, we parse the pdf on the fly. It can take many seconds.
        # We'll do this spec without mocks to make sure all the pieces still work.
        # HELIO-4467
        let(:monograph) { create(:public_monograph) }
        let(:pdf_ebook) { create(:public_file_set) }

        before do
          Hydra::Works::AddFileToFileSet.call(pdf_ebook, File.open(fixture_path + '/lorum_ipsum_toc.pdf'), :original_file)
          monograph.ordered_members << pdf_ebook
          monograph.save!
          UnpackJob.perform_now(pdf_ebook.id, 'pdf_ebook')
          FeaturedRepresentative.create(work_id: monograph.id, file_set_id: pdf_ebook.id, kind: 'pdf_ebook')
          # Remove the cache to force the pdf to be parsed
          EbookTableOfContentsCache.destroy_all
        end

        it "returns the intervals" do
          presenter = described_class.new(pdf_ebook.id)
          expect(presenter.intervals[0]).to be_an_instance_of(RemoveMeEPubIntervalPresenter)
          expect(presenter.intervals[0].title).to eq "The standard Lorem Ipsum passage, used since the 1500s"
          expect(presenter.intervals[0].cfi).to eq "page=3"
          expect(presenter.intervals[0].level).to be 1
          expect(presenter.intervals[3].level).to be 2
          expect(presenter.intervals[7].title).to eq "1914 translation by H. Rackham again"
        end
      end
    end
  end
end
