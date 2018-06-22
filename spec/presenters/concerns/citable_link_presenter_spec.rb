# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CitableLinkPresenter do
  class self::Presenter
    include CitableLinkPresenter
    attr_reader :id
    attr_reader :solr_document

    def initialize(id, solr_document)
      @id = id
      @solr_document = solr_document
    end
  end

  subject(:presenter) {  self.class::Presenter.new(id, solr_document) }

  let(:id) { 'validnoid' }
  let(:solr_document) { SolrDocument.new(hdl_ssim: [handle_path], doi_ssim: [doi_path]) }
  let(:handle_url) { 'http://hdl.handle.net/' + handle_path }
  let(:doi_url) { 'https://doi.org/' + doi_path }

  let(:handle_path) { '' }
  let(:doi_path) { '' }

  it 'default' do
    expect(subject.citable_link).to eq HandleService.url(id)
    expect(subject.doi_path).to eq doi_path
    expect(subject.doi_url).to eq doi_url
    expect(subject.handle_path).to eq HandleService.path(id)
    expect(subject.handle_url).to eq HandleService.url(id)
  end

  context 'explicit handle' do
    let(:handle_path) { '2027/fulcrum.identifier' }

    it do
      expect(subject.citable_link).to eq handle_url
      expect(subject.doi_path).to eq doi_path
      expect(subject.doi_url).to eq doi_url
      expect(subject.handle_path).to eq handle_path
      expect(subject.handle_url).to eq handle_url
    end

    context 'and explicit doi' do
      let(:doi_path) { '10.NNNN.N/identifier' }

      it do
        expect(subject.citable_link).to eq doi_url
        expect(subject.doi_path).to eq doi_path
        expect(subject.doi_url).to eq doi_url
        expect(subject.handle_path).to eq handle_path
        expect(subject.handle_url).to eq  handle_url
      end
    end
  end
end
