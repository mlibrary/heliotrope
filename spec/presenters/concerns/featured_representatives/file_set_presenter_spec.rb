# frozen_string_literal: true

require 'rails_helper'

class TestFileSetPresenter
  include FeaturedRepresentatives::FileSetPresenter
  attr_reader :solr_document

  def initialize(solr_document)
    @solr_document = solr_document
  end

  def id
    @solr_document['id']
  end

  def monograph_id
    @solr_document['monograph_id']
  end
end

describe FeaturedRepresentatives::FileSetPresenter do
  context "if a featured_representative's kind is epub" do
    subject { TestFileSetPresenter.new(SolrDocument.new(id: 'fid1', monograph_id: 'mid')) }
    let!(:fr) { create(:featured_representative, file_set_id: 'fid1', monograph_id: 'mid', kind: 'epub') }
    after { FeaturedRepresentative.destroy_all }

    describe "#featured_representative?" do
      it "is a featured_representative" do
        expect(subject.featured_representative?).to be true
      end
    end

    describe "#featured_representative" do
      it "returns the featured_representative" do
        expect(subject.featured_representative.file_set_id).to eq 'fid1'
        expect(subject.featured_representative).to be_an_instance_of(FeaturedRepresentative)
      end
    end

    describe "#epub?" do
      it "is an epub" do
        expect(subject.epub?).to be true
      end

      context "lock" do
        let(:epub_entity) { Entity.new(type: :epub, identifier: 'fid1') }

        before { allow(Subscription).to receive(:find_by).with(subscriber: epub_entity.id, publication: epub_entity.id).and_return(subscription) }

        context "unlocked" do
          let(:subscription) { nil }

          it do
            expect(subject.epub_locked?).to be false
            expect(subject.epub_unlocked?).to be true
          end
        end

        context "locked" do
          let(:subscription) { double('subscription') }

          it do
            expect(subject.epub_locked?).to be true
            expect(subject.epub_unlocked?).to be false
          end
        end
      end
    end
  end

  context "if a featured_representatives's kind is webgl" do
    subject { TestFileSetPresenter.new(SolrDocument.new(id: 'fid2', monograph_id: 'mid')) }
    let!(:fr) { create(:featured_representative, file_set_id: 'fid2', monograph_id: 'mid', kind: 'webgl') }
    after { FeaturedRepresentative.destroy_all }

    describe "#webgl?" do
      it "is a webgl" do
        expect(subject.webgl?).to be true
      end
    end
  end

  context "if the file_set is not a featured_representative" do
    subject { TestFileSetPresenter.new(SolrDocument.new(id: 'fid', monograph_id: 'mid')) }

    describe "#featured_representative?" do
      it "is false" do
        expect(subject.featured_representative?).to be false
      end
    end

    describe "#featured_representative" do
      it "is nil" do
        expect(subject.featured_representative).to be nil
      end
    end

    describe "epub?" do
      it "is false" do
        expect(subject.epub?).to be false
      end
    end

    describe "webgl?" do
      it "is false" do
        expect(subject.webgl?).to be false
      end
    end
  end
end
