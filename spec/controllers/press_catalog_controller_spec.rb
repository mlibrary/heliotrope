# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressCatalogController, type: :controller do
  let(:press) { create :press }

  describe "GET #index" do
    it "redirects to presses" do
      get :index, params: { subdomain: "subdomain" }
      expect(response).to redirect_to(presses_path)
    end
    it "returns http success" do
      get :index, params: { subdomain: press }
      expect(response).to have_http_status(:success)
    end
  end
end
