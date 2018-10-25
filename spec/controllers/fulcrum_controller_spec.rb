# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FulcrumController, type: :controller do
  let(:user) { create :user }

  describe "GET #dashboard" do
    it 'anonymous' do
      get :dashboard, params: { locale: 'en' }
      expect(response).to redirect_to('/login')
    end

    it "authenticated" do
      cosign_sign_in user
      get :dashboard, params: { locale: 'en' }
      expect(response).to redirect_to('/fulcrum/dashboard?locale=en')
    end
  end

  describe "GET #index" do
    context 'invalid partials' do
      it 'anonymous' do
        get :index, params: { locale: 'en', partials: :invalids }
        expect(response).to redirect_to('/login')
      end

      it 'authenticated' do
        cosign_sign_in user
        get :index, params: { locale: 'en', partials: :invalids }
        expect(response).to be_unauthorized
      end
    end

    context 'valid partials' do
      it 'anonymous' do
        get :index, params: { locale: 'en', partials: :users }
        expect(response).to redirect_to('/login')
      end

      it 'authenticated' do
        cosign_sign_in user
        get :index, params: { locale: 'en', partials: :users }
        expect(response).to be_success
      end
    end
  end

  describe "GET #show" do
    context 'invalid partials' do
      it 'anonymous' do
        get :show, params: { locale: 'en', partials: :invalids, id: :invalid }
        expect(response).to redirect_to('/login')
      end

      it 'authenticated' do
        cosign_sign_in user
        get :show, params: { locale: 'en', partials: :invalids, id: :invalid }
        expect(response).to be_unauthorized
      end
    end

    context 'valid partials' do
      it 'anonymous' do
        get :show, params: { locale: 'en', partials: :users, id: Base64.urlsafe_encode64(user.email) }
        expect(response).to redirect_to('/login')
      end

      it 'authenticated' do
        cosign_sign_in user
        get :show, params: { locale: 'en', partials: :users, id: Base64.urlsafe_encode64(user.email) }
        expect(response).to be_success
      end
    end
  end
end
