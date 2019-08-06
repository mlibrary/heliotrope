# frozen_string_literal: true

require 'rails_helper'

class TestMonographPresenter
  include FeaturedRepresentatives::MonographPresenter
  attr_reader :solr_document

  def initialize(solr_document)
    @solr_document = solr_document
  end

  def id
    @solr_document['id']
  end

  def ordered_member_docs
    [
      SolrDocument.new(id: 'epubid'),
      SolrDocument.new(id: 'pdfebookid'),
      SolrDocument.new(id: 'webglid'),
      SolrDocument.new(id: 'dbid'),
      SolrDocument.new(id: 'aboutid'),
      SolrDocument.new(id: 'reviewsid'),
      SolrDocument.new(id: 'relatedid'),
      SolrDocument.new(id: 'peerreviewid')
    ]
  end

  def current_ability
    nil
  end

  def request
    nil
  end
end

RSpec.describe FeaturedRepresentatives::MonographPresenter do
  context "with featured_representatives" do
    describe "#featured_representatives" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before do
        FeaturedRepresentative.create(
          [
            { monograph_id: 'mid', file_set_id: 'epubid', kind: 'epub' },
            { monograph_id: 'mid', file_set_id: 'webglid', kind: 'webgl' },
            { monograph_id: 'mid', file_set_id: 'dbid', kind: 'database' },
            { monograph_id: 'mid', file_set_id: 'aboutid', kind: 'aboutware' },
            { monograph_id: 'mid', file_set_id: 'reviewsid', kind: 'reviews' },
            { monograph_id: 'mid', file_set_id: 'relatedid', kind: 'related' },
            { monograph_id: 'mid', file_set_id: 'peerreviewid', kind: 'peer_review' }
          ]
        )
      end

      after { FeaturedRepresentative.destroy_all }

      it "returns FeaturedRepresentatives" do
        expect(subject.featured_representatives.count).to be 7
      end
    end

    context "EPUB representative" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'epubid', kind: 'epub') }

      after { FeaturedRepresentative.destroy_all }

      describe "#epub?" do
        it "returns true" do
          expect(subject.epub?).to be true
        end
      end

      describe "#epub_id" do
        it "returns the epub_id" do
          expect(subject.epub_id).to eq 'epubid'
        end
      end

      describe "#epub" do
        it "returns the epub's solr_doc" do
          expect(subject.epub['id']).to eq 'epubid'
        end
      end

      describe "#epub_presenter" do
        it "returns a presenter" do
          expect(subject.epub_presenter).to be_an_instance_of(EPubPresenter)
        end
      end

      describe "#pdf_ebook?" do
        it "returns false" do
          expect(subject.pdf_ebook?).to be false
        end
      end

      describe "#pdf_ebook_id" do
        it "returns nil" do
          expect(subject.pdf_ebook_id).to be nil
        end
      end

      describe "#pdf_ebook" do
        it "returns nil" do
          expect(subject.pdf_ebook).to be nil
        end
      end

      describe "#reader_ebook?" do
        it "returns true" do
          expect(subject.reader_ebook?).to be true
        end
      end

      describe "#reader_ebook_id" do
        it "returns the epub's id" do
          expect(subject.reader_ebook_id).to eq 'epubid'
        end
      end

      describe "#reader_ebook" do
        it "returns the epub's solr_doc" do
          expect(subject.epub['id']).to eq 'epubid'
        end
      end
    end

    context "PDF representative" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before do
        FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'pdfebookid', kind: 'pdf_ebook')
      end

      after { FeaturedRepresentative.destroy_all }

      describe "#epub?" do
        it "returns false" do
          expect(subject.epub?).to be false
        end
      end

      describe "#epub_id" do
        it "returns nil" do
          expect(subject.epub_id).to be nil
        end
      end

      describe "#epub" do
        it "returns nil" do
          expect(subject.epub).to be nil
        end
      end

      describe "#pdf_ebook?" do
        it "returns true" do
          expect(subject.pdf_ebook?).to be true
        end
      end

      describe "#pdf_ebook_id" do
        it "returns the pdf_ebook_id" do
          expect(subject.pdf_ebook_id).to eq 'pdfebookid'
        end
      end

      describe "#pdf_ebook" do
        it "returns the pdf_ebook's solr_doc" do
          expect(subject.pdf_ebook['id']).to eq 'pdfebookid'
        end
      end

      describe "#pdf_ebook_presenter" do
        it "returns a presenter" do
          expect(subject.pdf_ebook_presenter).to be_an_instance_of(PDFEbookPresenter)
        end
      end

      describe "#reader_ebook?" do
        it "is true" do
          expect(subject.reader_ebook?).to be true
        end
      end

      describe "#reader_ebook_id" do
        it "returns the pdf_ebook's id" do
          expect(subject.reader_ebook_id).to eq 'pdfebookid'
        end
      end

      describe "#reader_ebook" do
        it "returns the pdf_ebook's solr_doc" do
          expect(subject.reader_ebook['id']).to eq 'pdfebookid'
        end
      end
    end

    context "Both EPUB and PDF representatives" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before do
        FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'pdfebookid', kind: 'pdf_ebook')
        FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'epubid', kind: 'epub')
      end

      describe "#epub?" do
        it "returns true" do
          expect(subject.epub?).to be true
        end
      end

      describe "#epub_id" do
        it "returns the epub_id" do
          expect(subject.epub_id).to eq 'epubid'
        end
      end

      describe "#epub" do
        it "returns the epub's solr_doc" do
          expect(subject.epub['id']).to eq 'epubid'
        end
      end

      describe "#epub_presenter" do
        it "returns a presenter" do
          expect(subject.epub_presenter).to be_an_instance_of(EPubPresenter)
        end
      end

      describe "#pdf_ebook?" do
        it "returns true" do
          expect(subject.pdf_ebook?).to be true
        end
      end

      describe "#pdf_ebook_id" do
        it "returns the pdf_ebook_id" do
          expect(subject.pdf_ebook_id).to eq 'pdfebookid'
        end
      end

      describe "#pdf_ebook" do
        it "returns the pdf_ebook's solr_doc" do
          expect(subject.pdf_ebook['id']).to eq 'pdfebookid'
        end
      end

      describe "#pdf_ebook_presenter" do
        it "returns a presenter" do
          expect(subject.pdf_ebook_presenter).to be_an_instance_of(PDFEbookPresenter)
        end
      end

      describe "#reader_ebook?" do
        it "is true" do
          expect(subject.reader_ebook?).to be true
        end
      end

      describe "#reader_ebook_id" do
        it "returns the epub's id, giving precedence to the epub" do
          expect(subject.reader_ebook_id).to eq 'epubid'
        end
      end

      describe "#reader_ebook" do
        it "returns the epub's solr_doc, giving precedence to the epub" do
          expect(subject.epub['id']).to eq 'epubid'
        end
      end
    end

    context "webgl methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'webglid', kind: 'webgl') }

      after { FeaturedRepresentative.destroy_all }

      describe "#webgl?" do
        it "has a webgl" do
          expect(subject.webgl?).to be true
        end
      end

      describe "#webgl_id" do
        it "has a webgl_id" do
          expect(subject.webgl_id).to eq 'webglid'
        end
      end

      describe "#webgl" do
        it "returns the webgl's solr doc" do
          expect(subject.webgl['id']).to eq 'webglid'
        end
      end
    end

    context "database methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'dbid', kind: 'database') }

      after { FeaturedRepresentative.destroy_all }

      describe "#database?" do
        it "has a database" do
          expect(subject.database?).to be true
        end
      end

      describe "#database_id" do
        it "has a datatabase id" do
          expect(subject.database_id).to eq 'dbid'
        end
      end

      describe "#database" do
        it "returns the database's presenter" do
          expect(subject.database.id).to eq 'dbid'
        end
      end
    end

    context "aboutware methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'aboutid', kind: 'aboutware') }

      after { FeaturedRepresentative.destroy_all }

      describe "#aboutware?" do
        it "has aboutware" do
          expect(subject.aboutware?).to be true
        end
      end

      describe "#aboutware_id" do
        it "has an aboutware id" do
          expect(subject.aboutware_id).to eq 'aboutid'
        end
      end

      describe "#aboutware" do
        # This returns a FileSetPresenter, not a solr doc. TODO: inconsistency is bad.
        it "returns a FileSetPresenter" do
          expect(subject.aboutware).to be_an_instance_of(Hyrax::FileSetPresenter)
        end
      end
    end

    context "reviews methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'reviewsid', kind: 'reviews') }

      after { FeaturedRepresentative.destroy_all }

      describe "#reviews?" do
        it "has reviews" do
          expect(subject.reviews?).to be true
        end
      end

      describe "#reviews_id" do
        it "has a reviews id" do
          expect(subject.reviews_id).to eq 'reviewsid'
        end
      end

      describe "#reviews" do
        # This returns a FileSetPresenter, not a solr doc. TODO: inconsistency is bad. Consistently inconsistent OK tho?
        it "returns a FileSetPresenter" do
          expect(subject.reviews).to be_an_instance_of(Hyrax::FileSetPresenter)
        end
      end
    end

    context "related methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'relatedid', kind: 'related') }

      after { FeaturedRepresentative.destroy_all }

      describe "#related?" do
        it "has related" do
          expect(subject.related?).to be true
        end
      end

      describe "#related_id" do
        it "has a related id" do
          expect(subject.related_id).to eq 'relatedid'
        end
      end

      describe "#related" do
        # This returns a FileSetPresenter, not a solr doc. TODO: inconsistency is bad. Consistently inconsistent OK tho ;-) ?
        it "returns a FileSetPresenter" do
          expect(subject.related).to be_an_instance_of(Hyrax::FileSetPresenter)
        end
      end
    end

    context "peer_review methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'peerreviewid', kind: 'peer_review') }

      after { FeaturedRepresentative.destroy_all }

      describe "#peer_review?" do
        it "has peer_review" do
          expect(subject.peer_review?).to be true
        end
      end

      describe "#peer_review_id" do
        it "has a peer_review_id" do
          expect(subject.peer_review_id).to eq 'peerreviewid'
        end
      end

      describe "#peer_review" do
        # This returns a FileSetPresenter, not a solr doc. TODO: inconsistency is bad. Consistently inconsistent OK tho?
        it "returns a FileSetPresenter" do
          expect(subject.peer_review).to be_an_instance_of(Hyrax::FileSetPresenter)
        end
      end
    end
  end

  context "with no featured representatives" do
    subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }

    describe "#featured_representatives" do
      it { expect(subject.featured_representatives.empty?).to be true }
    end

    describe '#epub?' do
      it { expect(subject.epub?).to be false }
    end

    describe '#epub_id' do
      it { expect(subject.epub_id).to be nil }
    end

    describe '#epub' do
      it { expect(subject.epub).to be nil }
    end

    describe '#webgl?' do
      it { expect(subject.webgl?).to be false }
    end

    describe '#webgl' do
      it { expect(subject.webgl).to be nil }
    end

    describe '#webgl_id' do
      it { expect(subject.webgl_id).to be nil }
    end

    describe '#database?' do
      it { expect(subject.database?).to be false }
    end

    describe '#database' do
      it { expect(subject.database).to be nil }
    end

    describe '#database_id' do
      it { expect(subject.database_id).to be nil }
    end

    describe '#aboutware?' do
      it { expect(subject.aboutware?).to be false }
    end

    describe '#aboutware' do
      it { expect(subject.aboutware).to be nil }
    end

    describe '#aboutware_id' do
      it { expect(subject.aboutware_id).to be nil }
    end

    describe '#reviews?' do
      it { expect(subject.reviews?).to be false }
    end

    describe '#reviews' do
      it { expect(subject.reviews).to be nil }
    end

    describe '#reviews_id' do
      it { expect(subject.reviews_id).to be nil }
    end

    describe '#related?' do
      it { expect(subject.related?).to be false }
    end

    describe '#related' do
      it { expect(subject.related).to be nil }
    end

    describe '#related_id' do
      it { expect(subject.related_id).to be nil }
    end

    describe '#peer_review?' do
      it { expect(subject.peer_review?).to be false }
    end

    describe '#peer_review' do
      it { expect(subject.peer_review).to be nil }
    end

    describe '#peer_review_id' do
      it { expect(subject.peer_review_id).to be nil }
    end
  end
end
