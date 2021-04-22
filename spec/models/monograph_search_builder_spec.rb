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

    describe '#filter_out_miscellaneous' do
      it do
        solr_params = { fq: [] }
        search_builder.filter_out_miscellaneous(solr_params)
        expect(solr_params[:fq]).to be_empty
      end

      context 'representative_id' do
        it do
          m = create(:public_monograph, id: id)
          fs = create(:public_file_set)
          m.representative_id = fs.id
          m.save!
          solr_params = { fq: [] }
          search_builder.filter_out_miscellaneous(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-id:#{fs.id}")
        end
      end

      context 'tombstone' do
        it do
          m = create(:public_monograph, id: id)
          fs = create(:public_file_set, tombstone: 'yes')
          m.ordered_members << fs
          m.save!
          solr_params = { fq: [] }
          search_builder.filter_out_miscellaneous(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-id:#{fs.id}")
        end
      end

      context 'permissions_expiration_date' do
        it do
          m = create(:public_monograph, id: id)
          fs = create(:public_file_set, permissions_expiration_date: 1.day.ago.utc.strftime('%Y-%m-%d'))
          m.ordered_members << fs
          m.save!
          solr_params = { fq: [] }
          search_builder.filter_out_miscellaneous(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-id:#{fs.id}")
        end
      end
    end

    describe '#filter_out_representatives' do
      it do
        solr_params = { fq: [] }
        search_builder.filter_out_representatives(solr_params)
        expect(solr_params[:fq]).to be_empty
      end

      context 'representatives' do
        it do
          create(:featured_representative, work_id: id, file_set_id: '1', kind: 'epub')
          create(:featured_representative, work_id: id, file_set_id: '2', kind: 'pdf_ebook')
          solr_params = { fq: [] }
          search_builder.filter_out_representatives(solr_params)
          expect(solr_params[:fq]).to contain_exactly("-id:(1,2)")
        end
      end
    end

    describe '#filter_out_tombstones' do
      it do
        solr_params = { fq: [] }
        search_builder.filter_out_tombstones(solr_params)
        expect(solr_params[:fq]).to contain_exactly("-tombstone_ssim:[* TO *]")
      end
    end
  end
end
