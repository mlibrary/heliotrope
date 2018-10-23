# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FulcrumController, type: :controller do
  describe "GET #index" do
    context 'unauthenticated user' do
      before { get :index, params: { locale: 'en' } }

      it { expect(response).to redirect_to('/login') }
    end

    context "authenticated user" do
      let(:user) { create :user }

      before do
        cosign_sign_in user
        get :index
      end

      it { expect(response).not_to be_unauthorized }
      it { expect(response).to redirect_to("/fulcrum/dashboard?locale=en") }
    end
  end

  describe "GET #show" do
    let(:partial) { 'dashboard' }

    context 'unauthenticated user' do
      before { get :show, params: { locale: 'en', partial: partial } }

      it { expect(response).to redirect_to('/login') }
    end

    context "authenticated user" do
      let(:user) { create :user }

      before do
        cosign_sign_in user
        get :show, params: { partial: partial }
      end

      it { expect(response).not_to be_unauthorized }
      it { expect(response).to be_success }

      context "invalid partial" do
        let(:partial) { 'invalid' }

        it { expect(response).to be_unauthorized }
      end
    end
  end
end
