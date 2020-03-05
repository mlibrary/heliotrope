# frozen_string_literal: true

require 'rails_helper'

describe PressSearchBuilder do
  let(:search_builder) { described_class.new(context) }
  let(:context) { double('context', blacklight_config: config) }
  let(:config) { CatalogController.blacklight_config }
  let(:solr_params) { { fq: [] } }

  it { expect(search_builder).not_to be nil }

  describe "#filter_by_press" do
    context 'a press with no monographs' do
      let(:press) { create(:press) }

      before do
        search_builder.blacklight_params['press'] = press.subdomain
        search_builder.filter_by_press(solr_params)
      end

      it "creates an empty query for the press subdomain" do
        expect(solr_params[:fq].first).to eq("{!terms f=press_sim}#{press.subdomain}")
      end
    end
  end

  describe '#default_sort_field' do
    subject { search_builder.default_sort_field }

    let(:default_sort_field) { double('default_sort_field') }
    let(:sort_fields) { double('sort_fields') }
    let(:press) { 'press' }

    before do
      allow(search_builder).to receive(:blacklight_params).and_return({ 'press' => press })
      allow(config).to receive(:default_sort_field).and_return(default_sort_field)
      allow(config).to receive(:sort_fields).and_return(sort_fields)
    end

    it { is_expected.to be default_sort_field }

    context 'barpublishing' do
      let(:press) { 'barpublishing' }
      let(:year_desc) { double('year_desc') }

      before { allow(sort_fields).to receive(:[]).with('year desc').and_return(year_desc) }

      it { is_expected.to be year_desc }
    end
  end
end
