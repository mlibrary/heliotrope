# frozen_string_literal: true

require 'rails_helper'

describe CatalogSearchBuilder do
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:search_builder) { described_class.new(context) }
  let(:solr_params) { { fq: [] } }

  describe '#filter_published_monographs_for_oai' do
    context 'when handling OAI requests' do
      before do
        allow(search_builder).to receive(:blacklight_params).and_return({ verb: 'ListRecords' })
      end

      it 'applies published monograph constraints' do
        search_builder.filter_published_monographs_for_oai(solr_params)
        expect(solr_params[:fq]).to contain_exactly(
          '{!terms f=has_model_ssim}Monograph',
          'visibility_ssi:open',
          '-suppressed_bsi:true'
        )
      end
    end

    context 'when handling non-OAI requests' do
      before do
        allow(search_builder).to receive(:blacklight_params).and_return({})
      end

      it 'does not add OAI filters' do
        search_builder.filter_published_monographs_for_oai(solr_params)
        expect(solr_params[:fq]).to eq([])
      end
    end

    context 'when handling OAI ListIdentifiers requests' do
      before do
        allow(search_builder).to receive(:blacklight_params).and_return({ verb: 'ListIdentifiers' })
      end

      it 'applies published monograph constraints' do
        search_builder.filter_published_monographs_for_oai(solr_params)
        expect(solr_params[:fq]).to contain_exactly(
          '{!terms f=has_model_ssim}Monograph',
          'visibility_ssi:open',
          '-suppressed_bsi:true'
        )
      end
    end
  end
end
