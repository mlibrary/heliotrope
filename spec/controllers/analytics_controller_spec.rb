# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsController, type: :controller do
  describe "GET #show" do
    context 'unauthenticated user' do
      before { get :show }

      it { expect(response).to redirect_to('/login') }
    end

    context "authenticated user" do
      before do
        cosign_sign_in current_user
        get :show
      end

      context "non-admin" do
        let(:current_user) { create(:user) }

        it { expect(response).to be_unauthorized }
      end

      context "platform admin" do
        let(:current_user) { create(:platform_admin) }

        it { expect(response).not_to be_unauthorized }
        it { expect(response).to be_success }
      end
    end
  end
end
