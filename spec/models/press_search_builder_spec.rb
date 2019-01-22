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
end
