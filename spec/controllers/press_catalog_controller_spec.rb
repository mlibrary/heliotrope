# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressCatalogController, type: :controller do
  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'search_builder_class' do
      expect(blacklight_config.search_builder_class).to be PressSearchBuilder
    end
  end

  describe 'controller' do
    it '#show_site_search?' do
      expect(controller.show_site_search?).to equal true
    end
  end

  describe "GET #index" do
    let(:press) { create :press }

    it "returns http 'not found' when press param is not a known Press subdomain" do
      get :index, params: { press: "press" }
      expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
      expect(response).to have_http_status(:not_found)
    end
    it "returns http 'success' when press param is a known Press subdomain" do
      get :index, params: { press: press }
      expect(response).to have_http_status(:success)
      expect(controller.instance_variable_get(:@auth)).to be_an_instance_of(Auth)
      expect(controller.instance_variable_get(:@auth).return_location).to eq Rails.application.routes.url_helpers.press_catalog_path(press)
    end

    context '#search_ongoing' do
      it 'is false with no additional params' do
        get :index, params: { press: press }
        expect(assigns(:search_ongoing)).to eq false
      end

      it 'is false with additional non-search-related params' do
        get :index, params: { press: press, page: 2, per_page: 50, sort: 'year desc', view: 'list' }
        expect(assigns(:search_ongoing)).to eq false
      end

      it 'is true with a text search query param' do
        get :index, params: { press: press, q: 'search terms' }
        expect(assigns(:search_ongoing)).to eq true
      end

      it 'is true with a facet param' do
        get :index, params: { press: press, open_access_sim: 'yes' }
        expect(assigns(:search_ongoing)).to eq true
      end
    end
  end

  # inspired by https://github.com/samvera/hyrax/blob/6182f8c778c52bff1f2832173595f12c038b2793/spec/controllers/catalog_controller_spec.rb#L86
  context 'Finding Monographs using FileSet metadata' do
    before do
      create(:press, subdomain: 'michigan')
      create(:press, subdomain: 'barpublishing')
      objects.each { |obj| ActiveFedora::SolrService.add(obj.to_solr) }
      ActiveFedora::SolrService.commit
    end

    let(:objects) do
      [double(to_solr: file_set_1), double(to_solr: file_set_2),
       double(to_solr: monograph_1), double(to_solr: monograph_2)]
    end

    let(:monograph_1) do
      {
        has_model_ssim: ['Monograph'],
        id: 'ff365c76z',
        title_tesim: ['you too'],
        file_set_ids_ssim: ['ff365c78h'],
        read_access_group_ssim: ['public'],
        visibility_ssi: 'open',
        suppressed_bsi: false,
        press_sim: 'michigan'
      }
    end

    let(:monograph_2) do
      {
        has_model_ssim: ['Monograph'],
        id: 'ff365c777',
        title_tesim: ['find me'],
        file_set_ids_ssim: ['ff365c79s'],
        read_access_group_ssim: ["public"],
        visibility_ssi: 'open',
        suppressed_bsi: false,
        press_sim: 'barpublishing'
      }
    end

    let(:file_set_1) do
      {
        has_model_ssim: ['FileSet'],
        id: 'ff365c78h',
        title_tesim: ['first file title'],
        all_text_timv: 'blahdy blah',
        file_set_ids_ssim: [],
        visibility_ssi: 'open'
      }
    end

    let(:file_set_2) do
      {
        has_model_ssim: ['FileSet'],
        id: 'ff365c79s',
        title_tesim: ['second file title'],
        all_text_timv: 'yadda yadda',
        file_set_ids_ssim: [],
        visibility_ssi: 'open'
      }
    end

    describe 'in a press other than "barpublishing"' do
      it "won't find a Monograph by matching one of its FileSet's titles" do
        get :index, params: { q: 'first file title', press: 'michigan' }
        expect(assigns(:response).docs.map(&:id)).to eq []
      end

      it "won't find a Monograph by matching one of its FileSet's extracted text" do
        get :index, params: { q: 'blahdy blah', press: 'michigan' }
        expect(assigns(:response).docs.map(&:id)).to eq []
      end
    end

    describe 'in "barpublishing" press' do
      it "will find a Monograph by matching one of its FileSet's titles" do
        get :index, params: { q: 'second file title', press: 'barpublishing' }
        expect(assigns(:response).docs.map(&:id)).to contain_exactly(monograph_2[:id])
      end

      it "will find a Monograph by matching one of its FileSet's extracted text" do
        get :index, params: { q: 'yadda yadda', press: 'barpublishing' }
        expect(assigns(:response).docs.map(&:id)).to contain_exactly(monograph_2[:id])
      end
    end
  end
end
