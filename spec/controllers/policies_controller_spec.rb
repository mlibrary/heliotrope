# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PoliciesController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # Policy. As you add validations to Policy,
  # be sure to adjust the attributes here as well.
  let(:valid_attributes) do
    {
      agent_type: 'any',
      agent_id: 'any',
      agent_token: 'any:any',
      credential_type: 'permission',
      credential_id: 'read',
      credential_token: 'permission:read',
      resource_type: 'any',
      resource_id: 'any',
      resource_token: 'any:any',
      zone_id: Checkpoint::DB::Permit.default_zone
    }
  end
  let(:invalid_attributes) do
    {
      agent_type: "",
      agent_id: "",
      agent_token: "",
      credential_type: "",
      credential_id: "",
      credential_token: "",
      resource_type: "",
      resource_id: "",
      resource_token: "",
      zone_id: ""
    }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PoliciesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before { PermissionService.clear_permits_table }

  describe "GET #index" do
    it "returns a success response" do
      _policy = Policy.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      policy = Policy.create! valid_attributes
      get :show, params: { id: policy.to_param }, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:show)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Policy" do
        expect {
          post :create, params: { policy: valid_attributes }, session: valid_session
        }.to change(Policy, :count).by(1)
      end

      it "redirects to the created policy" do
        post :create, params: { policy: valid_attributes }, session: valid_session
        expect(response).to redirect_to(Policy.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { policy: invalid_attributes }, session: valid_session
        expect(response).to be_success
        expect(response).to render_template(:new)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested policy" do
      policy = Policy.create! valid_attributes
      expect {
        delete :destroy, params: { id: policy.to_param }, session: valid_session
      }.to change(Policy, :count).by(-1)
    end

    it "redirects to the policies list" do
      policy = Policy.create! valid_attributes
      delete :destroy, params: { id: policy.to_param }, session: valid_session
      expect(response).to redirect_to(policies_url)
    end
  end
end
