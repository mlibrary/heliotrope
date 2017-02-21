require 'rails_helper'

RSpec.describe EmbedController, type: :controller do
  describe "GET #show" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
