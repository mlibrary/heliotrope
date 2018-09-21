# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermitsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # Permit. As you add validations to Permit, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    {
      agent_type: "agent_type",
      agent_id: "agent_id",
      agent_token: "agent_token",
      credential_type: "credential_type",
      credential_id: "credentail_id",
      credential_token: "credential_token",
      resource_type: "resource_type",
      resource_id: "resource_id",
      resource_token: "resource_token",
      zone_id: "zone_id"
    } }
  let(:invalid_attributes) {
    {
      agent_type: nil,
      agent_id: nil,
      agent_token: nil,
      credential_type: nil,
      credential_id: nil,
      credential_token: nil,
      resource_type: nil,
      resource_id: nil,
      resource_token: nil,
      zone_id: nil
    } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PermitsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      _permit = Permit.create!(valid_attributes)
      get :index, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      permit = Permit.create!(valid_attributes)
      get :show, params: { id: permit.to_param }, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      permit = Permit.create!(valid_attributes)
      get :edit, params: { id: permit.to_param }, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Permit" do
        expect {
          post :create, params: { permit: valid_attributes }, session: valid_session
        }.to change(Permit, :count).by(1)
      end

      it "redirects to the created permit" do
        post :create, params: { permit: valid_attributes }, session: valid_session
        expect(response).to redirect_to(Permit.last)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { permit: invalid_attributes }, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          agent_type: "new_agent_type",
          agent_id: "new_agent_id",
          agent_token: "new_agent_token",
          credential_type: "new_credential_type",
          credential_id: "new_credential_id",
          credential_token: "new_credential_token",
          resource_type: "new_resource_type",
          resource_id: "new_resource_id",
          resource_token: "new_resource_token",
          zone_id: "new_zone_id"
        } }

      it "updates the requested permit" do
        permit = Permit.create!(valid_attributes)
        put :update, params: { id: permit.to_param, permit: new_attributes }, session: valid_session
        permit.reload
        expect(permit.agent_type).to eq("new_agent_type")
        expect(permit.agent_id).to eq("new_agent_id")
        expect(permit.agent_token).to eq("new_agent_token")
        expect(permit.credential_type).to eq("new_credential_type")
        expect(permit.credential_id).to eq("new_credential_id")
        expect(permit.credential_token).to eq("new_credential_token")
        expect(permit.resource_type).to eq("new_resource_type")
        expect(permit.resource_id).to eq("new_resource_id")
        expect(permit.resource_token).to eq("new_resource_token")
        expect(permit.zone_id).to eq("new_zone_id")
      end

      it "redirects to the permit" do
        permit = Permit.create!(valid_attributes)
        put :update, params: { id: permit.to_param, permit: valid_attributes }, session: valid_session
        expect(response).to redirect_to(permit)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        permit = Permit.create!(valid_attributes)
        put :update, params: { id: permit.to_param, permit: invalid_attributes }, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested permit" do
      permit = Permit.create!(valid_attributes)
      expect {
        delete :destroy, params: { id: permit.to_param }, session: valid_session
      }.to change(Permit, :count).by(-1)
    end

    it "redirects to the permits list" do
      permit = Permit.create!(valid_attributes)
      delete :destroy, params: { id: permit.to_param }, session: valid_session
      expect(response).to redirect_to(permits_url)
    end
  end
end
