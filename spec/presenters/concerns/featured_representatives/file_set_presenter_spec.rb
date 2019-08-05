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

RSpec.describe FeaturedRepresentatives::FileSetPresenter do
  let(:presenter) { TestFileSetPresenter.new(SolrDocument.new(id: 'fid1', monograph_id: 'mid')) }

  context 'non featured representative file set' do
    describe '#featured_representative' do
      subject { presenter.featured_representative }

      it { is_expected.to be nil }
    end

    describe '#featured_representative?' do
      subject { presenter.featured_representative? }

      it { is_expected.to be false }
    end

    FeaturedRepresentative::KINDS.each do |kind|
      next unless TestFileSetPresenter.new(nil).respond_to?("#{kind}?".to_sym)
      describe "##{kind}?" do
        subject { presenter.send("#{kind}?".to_sym) }

        it { is_expected.to be false }
      end
    end
  end

  context 'featured representative file set' do
    let(:featured_representative) { instance_double(FeaturedRepresentative, 'featured_representative', kind: kind) }
    let(:kind) { 'kind' }

    before { allow(FeaturedRepresentative).to receive(:where).with(monograph_id: 'mid', file_set_id: 'fid1').and_return([featured_representative]) }

    describe '#featured_representative' do
      subject { presenter.featured_representative }

      it { is_expected.to be featured_representative }
    end

    describe '#featured_representative?' do
      subject { presenter.featured_representative? }

      it { is_expected.to be true }
    end

    FeaturedRepresentative::KINDS.each do |kind|
      next unless TestFileSetPresenter.new(nil).respond_to?("#{kind}?".to_sym)
      describe "##{kind}?" do
        subject { presenter.send("#{kind}?".to_sym) }

        it { is_expected.to be false }

        context kind.to_s do
          let(:kind) { kind }

          it { is_expected.to be true }
        end
      end
    end
  end
end
