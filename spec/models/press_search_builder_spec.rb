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
    let(:year_desc) { double('year_desc') }

    before do
      allow(search_builder).to receive(:blacklight_params).and_return({ 'press' => press })
      allow(config).to receive(:default_sort_field).and_return(default_sort_field)
      allow(config).to receive(:sort_fields).and_return(sort_fields)
      allow(sort_fields).to receive(:[]).with('year desc').and_return(year_desc)
    end

    it { is_expected.to be year_desc }

    context "params['q'].present?" do
      before do
        allow(search_builder).to receive(:blacklight_params).and_return({ 'press' => press, 'q' => 'query' })
      end

      it { is_expected.to be default_sort_field }
    end

    context 'heb' do
      let(:press) { 'heb' }
      it { is_expected.to be default_sort_field }
    end
  end

  describe "filter_by_product_access" do
    let(:press) { create(:press) }

    context "for a subscriber with access to OA, default, free, and purchased" do
      let(:current_actor) { Anonymous.new({}) }
      let(:free_results) { instance_double(ActiveRecord::Result, 'free_results') }
      let(:purchased_results) { instance_double(ActiveRecord::Result, 'purchased_results') }

      before do
        search_builder.blacklight_params['press'] = press.subdomain
        search_builder.blacklight_params['user_access'] = 'true' # the string 'true'
        search_builder.blacklight_config.current_actor = current_actor
        allow(Sighrax).to receive(:allow_read_products).and_return(free_results)
        allow(current_actor).to receive(:products).and_return(purchased_results)
        allow(free_results).to receive(:pluck).with(:id).and_return([2, 4])
        allow(purchased_results).to receive(:pluck).with(:id).and_return([1, 3])
      end

      it "creates a query for the books the user can access" do
        search_builder.filter_by_product_access(solr_params)
        expect(solr_params[:fq].first).to eq("{!terms f=products_lsim}-1,0,1,2,3,4")
      end
    end

    context "when only OA books should be shown" do
      before do
        search_builder.blacklight_params['press'] = press.subdomain
        search_builder.blacklight_params['user_access'] = "oa"
      end

      it "creates a query for the books the user can access" do
        search_builder.filter_by_product_access(solr_params)
        expect(solr_params[:fq].first).to eq("{!terms f=products_lsim}-1")
      end
    end
  end

  describe "#maybe_filter_draft_for_incognito" do
    before do
      search_builder.blacklight_config.current_actor = current_actor
    end

    context "a normal anonymous user" do
      let(:current_actor) { Anonymous.new({}) }

      it "does nothing (draft works are filtered out in Hyrax::SearchFilters via blacklight access control stuff)" do
        search_builder.maybe_filter_draft_for_incognito(solr_params)
        expect(solr_params[:fq]).to eq []
      end
    end

    context "a platform_admin" do
      let(:current_actor) { create(:platform_admin) }

      context "without Incognito set" do
        it "includes Draft works" do
          search_builder.maybe_filter_draft_for_incognito(solr_params)
          expect(solr_params[:fq]).to eq []
        end
      end

      context "with Incognito set" do
        it "filters out Draft works" do
          Incognito.allow_platform_admin(current_actor, false)
          search_builder.maybe_filter_draft_for_incognito(solr_params)
          expect(solr_params[:fq].first).to eq ("-visibility_ssi:restricted")
        end
      end
    end
  end
end
