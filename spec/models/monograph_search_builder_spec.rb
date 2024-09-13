# frozen_string_literal: true

require 'rails_helper'

describe MonographSearchBuilder do
  let(:search_builder) { described_class.new(context) }
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }

  describe '#monograph_id' do
    subject { search_builder.send(:monograph_id, blacklight_params) }

    let(:blacklight_params) { { 'id' => id } }
    let(:id) { 'validnoid' }

    before { allow(search_builder).to receive(:blacklight_params).and_return blacklight_params }

    it { is_expected.to eq id }

    context 'monograph id' do
      let(:blacklight_params) { { 'id' => id, monograph_id: monograph_id } }
      let(:monograph_id) { 'monograph' }

      it { is_expected.to eq monograph_id }
    end
  end

  describe 'filters' do
    let(:id) { 'validnoid' }

    before { allow(search_builder).to receive(:monograph_id).and_return id }

    describe '#filter_by_monograph_id' do
      it do
        solr_params = { fq: [] }
        search_builder.filter_by_monograph_id(solr_params)
        expect(solr_params[:fq]).to contain_exactly("{!terms f=monograph_id_ssim}#{id}")
      end
    end

    describe '#filter_out_representatives' do
      it do
        solr_params = { fq: [] }
        search_builder.filter_out_representatives(solr_params)
        expect(solr_params[:fq]).to be_empty
      end

      context 'representatives' do
        let(:monograph) { ::SolrDocument.new(id: id, has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: cover.id) }
        let(:cover) { ::SolrDocument.new(id: '999999999', has_model_ssim: ['FileSet'], visibility_ssi: 'open') }

        before do
          ActiveFedora::SolrService.add([monograph.to_h, cover.to_h])
          ActiveFedora::SolrService.commit
        end

        it do
          create(:featured_representative, work_id: id, file_set_id: '1', kind: 'epub')
          create(:featured_representative, work_id: id, file_set_id: '2', kind: 'pdf_ebook')
          create(:featured_representative, work_id: id, file_set_id: '3', kind: 'database')
          create(:featured_representative, work_id: id, file_set_id: '4', kind: 'webgl')
          solr_params = { fq: [] }
          search_builder.filter_out_representatives(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-id:(1 2)", "-id:999999999")
        end
      end
    end

    describe '#filter_out_tombstones' do
      it do
        travel_to(Time.zone.local(2022, 02, 02, 12, 00, 00)) do
          solr_params = { fq: [] }
          search_builder.filter_out_tombstones(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-permissions_expiration_date_ssim:[* TO 2022-02-02]", "-tombstone_ssim:[* TO *]")
        end
      end
    end
  end
end
