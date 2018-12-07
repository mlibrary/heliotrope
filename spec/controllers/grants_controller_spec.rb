# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrantsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # Grant. As you add validations to Grant,
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
      zone_id: Checkpoint::DB::Grant.default_zone
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
  # GrantsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:individual) { create(:individual) }
  let(:product) { create(:product) }

  before { clear_grants_table }

  describe "GET #index" do
    it "returns a success response" do
      Greensub.subscribe(individual, product)
      get :index, params: {}, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      Greensub.subscribe(individual, product)
      get :show, params: { id: grants_table_last.id }, session: valid_session
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
      it "creates a new Grant" do
        post :create, params: { grant: valid_attributes }, session: valid_session
        expect(grants_table_count).to eq(1)
        expect(response).to redirect_to(grants_url)
      end

      context "with permission:any" do
        before { valid_attributes[:credential_id] = 'any' }

        it do
          post :create, params: { grant: valid_attributes }, session: valid_session
          expect(grants_table_count).to eq(1)
          expect(response).to redirect_to(grants_url)
        end
      end

      context "with permission:unknown" do
        before do
          valid_attributes[:credential_id] = 'unknown'
          allow(ValidationService).to receive(:valid_credential?).with(valid_attributes[:credential_type].to_sym, valid_attributes[:credential_id]).and_return(true)
        end

        it do
          expect {
            post :create, params: { grant: valid_attributes }, session: valid_session
          }.to raise_error(ArgumentError)
        end
      end

      context "with unknown:any" do
        before do
          valid_attributes[:credential_type] = 'unknown'
          valid_attributes[:credential_id] = 'any'
          allow(ValidationService).to receive(:valid_credential?).with(valid_attributes[:credential_type].to_sym, valid_attributes[:credential_id]).and_return(true)
        end

        it do
          expect {
            post :create, params: { grant: valid_attributes }, session: valid_session
          }.to raise_error(ArgumentError)
        end
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { grant: invalid_attributes }, session: valid_session
        expect(response).to be_success
        expect(response).to render_template(:new)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested grant" do
      Greensub.subscribe(individual, product)
      delete :destroy, params: { id: grants_table_last.id }, session: valid_session
      expect(grants_table_count).to be_zero
      expect(response).to redirect_to(grants_url)
    end
  end
end
