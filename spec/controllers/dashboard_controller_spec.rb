# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe "GET #index" do
    context 'unauthenticated user' do
      before { get :index }
      # TODO: why no locale here?
      it { expect(response).to redirect_to('/users/sign_in') }
    end
    context "authenticated user" do
      let(:user) { create :user }

      before do
        sign_in user
        get :index
      end
      it { expect(response).to_not be_unauthorized }
      it { expect(response).to redirect_to("/dashboard/home?locale=en") }
    end
  end

  describe "GET #show" do
    let(:partial) { 'home' }

    context 'unauthenticated user' do
      before { get :show, params: { locale: 'en', partial: partial } }
      it { expect(response).to redirect_to('/users/sign_in') }
    end
    context "authenticated user" do
      let(:user) { create :user }

      before do
        sign_in user
        get :show, params: { partial: partial }
      end
      it { expect(response).to_not be_unauthorized }
      it { expect(response).to be_success }
      context "invalid partial" do
        let(:partial) { 'invalid' }

        it { expect(response).to be_unauthorized }
      end
    end
  end
end
