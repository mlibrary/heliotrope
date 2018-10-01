# frozen_string_literal: true

require 'rails_helper'

RSpec.describe APIRequestsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # APIRequest. As you add validations to APIRequest, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { user: nil, action: "action", path: "path", params: "{}", status: 0, exception: nil } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ComponentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      _api_request = APIRequest.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      api_request = APIRequest.create! valid_attributes
      get :show, params: { id: api_request.to_param }, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:show)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested api_request" do
      api_request = APIRequest.create! valid_attributes
      expect {
        delete :destroy, params: { id: api_request.to_param }, session: valid_session
      }.to change(APIRequest, :count).by(-1)
    end

    it "redirects to the components list" do
      api_request = APIRequest.create! valid_attributes
      delete :destroy, params: { id: api_request.to_param }, session: valid_session
      expect(response).to redirect_to(api_requests_url)
    end
  end
end
