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
      SolrDocument.new(id: 'webglid'),
      SolrDocument.new(id: 'dbid'),
      SolrDocument.new(id: 'aboutid')
    ]
  end

  def current_ability
    nil
  end

  def request
    nil
  end
end

describe FeaturedRepresentatives::MonographPresenter do
  context "with featured_representatives" do
    describe "#featured_representatives" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }
      before do
        FeaturedRepresentative.create(
          [
            { monograph_id: 'mid', file_set_id: 'epubid', kind: 'epub' },
            { monograph_id: 'mid', file_set_id: 'webglid', kind: 'webgl' },
            { monograph_id: 'mid', file_set_id: 'dbid', kind: 'database' },
            { monograph_id: 'mid', file_set_id: 'aboutid', kind: 'aboutware' }
          ]
        )
      end
      after { FeaturedRepresentative.destroy_all }
      it "returns FeaturedRepresentatives" do
        expect(subject.featured_representatives.count).to be 4
      end
    end

    context "epub methods" do
      subject { TestMonographPresenter.new(SolrDocument.new(id: 'mid')) }
      before { FeaturedRepresentative.create(monograph_id: 'mid', file_set_id: 'epubid', kind: 'epub') }
      after { FeaturedRepresentative.destroy_all }

      describe "#epub?" do
        it "has an epub" do
          expect(subject.epub?).to be true
        end
      end

      describe "#epub_id" do
        it "return the epub_id" do
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
          # How dumb is this? TODO: A better way to isolate and test this? Maybe it's fine...
          allow(FactoryService).to receive(:e_pub_publication).with('epubid').and_return(EPub::Publication.from('epubid'))
          expect(subject.epub_presenter).to be_an_instance_of(EPub::PublicationPresenter)
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
        it "returns the database's solr doc" do
          expect(subject.database['id']).to eq 'dbid'
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
  end
end
