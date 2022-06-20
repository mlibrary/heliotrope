# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CitableLinkPresenter do
  class self::Presenter # rubocop:disable Style/ClassAndModuleChildren
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
  let(:solr_document) { SolrDocument.new(hdl_ssim: [handle_path], doi_ssim: [doi_path], identifier_tesim: ['UUID', heb_id, 'GUID']) }
  let(:handle_url) { HandleNet::HANDLE_NET_PREFIX + handle_path }
  let(:heb_url) { HandleNet::HANDLE_NET_PREFIX + heb_path }
  let(:doi_url) { HandleNet::DOI_ORG_PREFIX + doi_path }

  let(:heb_id) { '' }
  let(:handle_path) { '' }
  let(:heb_path) { '' }
  let(:doi_path) { '' }

  it 'default' do
    expect(subject.citable_link).to eq HandleNet.url(id)
    expect(subject.doi?).to be false
    expect(subject.doi_path).to eq doi_path
    expect(subject.doi_url).to eq doi_url
    expect(subject.heb?).to be false
    expect(subject.heb_path).to eq heb_path
    expect(subject.heb_url).to eq heb_url
    expect(subject.handle_path).to eq HandleNet.path(id)
    expect(subject.handle_url).to eq HandleNet.url(id)
  end

  context 'explicit handle' do
    let(:handle_path) { '2027/fulcrum.identifier' }

    it do
      expect(subject.citable_link).to eq handle_url
      expect(subject.doi?).to be false
      expect(subject.doi_path).to eq doi_path
      expect(subject.doi_url).to eq doi_url
      expect(subject.heb?).to be false
      expect(subject.heb_path).to eq heb_path
      expect(subject.heb_url).to eq heb_url
      expect(subject.handle_path).to eq handle_path
      expect(subject.handle_url).to eq handle_url
    end

    context 'and explicit heb' do
      let(:heb_id) { '  heb_id:   HeB00001.0001.001' }
      let(:heb_path) { '2027/heb00001' }

      describe 'correct HEB ID' do
        it 'trims and downcases proper HEB IDs, uses the correct resulting HEB handle' do
          expect(subject.citable_link).to eq heb_url
          expect(subject.doi?).to be false
          expect(subject.doi_path).to eq doi_path
          expect(subject.doi_url).to eq doi_url
          expect(subject.heb?).to be true
          expect(subject.heb_path).to eq heb_path
          expect(subject.heb_url).to eq heb_url
          expect(subject.handle_path).to eq handle_path
          expect(subject.handle_url).to eq  handle_url
        end
      end

      context 'and explicit doi' do
        let(:doi_path) { '10.NNNN.N/identifier' }

        it do
          expect(subject.citable_link).to eq doi_url
          expect(subject.doi?).to be true
          expect(subject.doi_path).to eq doi_path
          expect(subject.doi_url).to eq doi_url
          expect(subject.heb?).to be true
          expect(subject.heb_path).to eq heb_path
          expect(subject.heb_url).to eq heb_url
          expect(subject.handle_path).to eq handle_path
          expect(subject.handle_url).to eq  handle_url
        end
      end

      describe 'when someone enters a bad HEB id, containing incorrect period in "heb."' do
        let(:heb_id) { 'heb_id: heb.00001.0001.001' }
        let(:heb_path) { '' }

        it 'ignores the value, falling back to handle for citable_link' do
          expect(subject.citable_link).to eq handle_url
          expect(subject.doi?).to be false
          expect(subject.doi_path).to eq doi_path
          expect(subject.doi_url).to eq doi_url
          expect(subject.heb?).to be false
          expect(subject.heb_path).to eq heb_path
          expect(subject.heb_url).to eq heb_url
          expect(subject.handle_path).to eq handle_path
          expect(subject.handle_url).to eq handle_url
        end
      end
    end
  end
end
