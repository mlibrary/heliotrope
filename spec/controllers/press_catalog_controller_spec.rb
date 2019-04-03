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

    it "redirects to presses" do
      get :index, params: { press: "press" }
      expect(response).to redirect_to(presses_path)
    end
    it "returns http success" do
      get :index, params: { press: press }
      expect(response).to have_http_status(:success)
    end
  end
end
