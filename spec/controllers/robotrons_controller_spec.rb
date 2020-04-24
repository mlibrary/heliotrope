# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RobotronsController, type: :controller do
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # GrantsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  # let(:current_actor) { instance_double(Anonymous, 'current_actor') }
  let(:ip) { 'ip' }

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    let(:robotron) { create(:robotron) }

    it "returns a success response" do
      get :show, params: { id: robotron.id }, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:show)
    end
  end

  describe "GET #trap" do
    let(:robotron) { create(:robotron) }

    it "returns a success response" do
      get :trap, params: { id: robotron.id, trap: "profile" }, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:trap)
    end
  end

  describe "DELETE #destroy" do
    let(:robotron) { create(:robotron) }

    it "destroys the requested robotron" do
      delete :destroy, params: { id: robotron.id }, session: valid_session
      expect(response).to redirect_to(robotrons_url)
      expect(Robotron.count).to be_zero
    end
  end
end
