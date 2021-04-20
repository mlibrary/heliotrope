# frozen_string_literal: true

require 'rails_helper'

class ResourcePresenter
  include TombstonePresenter
  attr_reader :solr_document

  def initialize(solr_document)
    @solr_document = solr_document
  end
end

class WorkPresenter < ResourcePresenter
  def representative_id
    'validnoid'
  end
end

RSpec.describe TombstonePresenter do
  let(:presenter) { ResourcePresenter.new(solr_document) }
  let(:solr_document) { SolrDocument.new(options) }
  let(:options) { {} }

  describe '#tombstone?' do
    subject { presenter.tombstone? }

    it { is_expected.to be false }

    context 'when tombstone' do
      before { options[Solrizer.solr_name('tombstone', :symbol)] = 'YeS' }

      it { is_expected.to be true }
    end
  end

  describe '#tombstone_message' do
    subject { presenter.tombstone_message }

    let(:model) { instance_double(Sighrax::Model, 'model', tombstone_message: model_tombstone_message) }
    let(:model_tombstone_message) { }

    before { allow(Sighrax).to receive(:from_solr_document).with(presenter.solr_document).and_return model }

    it { is_expected.to be nil }

    context 'when model tombstone message' do
      let(:model_tombstone_message) { '_Model_ Tombstone Message' }

      it { is_expected.to eq model_tombstone_message }
    end
  end

  describe '#tombstone_thumbnail?' do
    subject { presenter.tombstone_thumbnail? }

    it { is_expected.to be true }

    context 'when representative' do
      let(:presenter) { WorkPresenter.new(solr_document) }
      let(:representative) { instance_double(Sighrax::Resource, 'representative', tombstone?: tombstone) }
      let(:tombstone) { double('boolean') }

      before { allow(Sighrax).to receive(:from_noid).with(presenter.representative_id).and_return representative }

      it { is_expected.to be tombstone }
    end
  end

  describe '#tombstone_thumbnail_tag' do
    subject { presenter.tombstone_thumbnail_tag(width, options) }

    let(:width) { 225 }
    let(:options) { {} }
    let(:image_tag) { double('image_tag') }

    before { allow(ActionController::Base.helpers).to receive(:image_tag).with('tombstone.svg', style: "max-width: #{width}px").and_return image_tag }

    it { is_expected.to be image_tag }
  end
end
