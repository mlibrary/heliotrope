# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsController, type: :controller do
  describe "GET #show" do
    context 'unauthenticated user' do
      before { get :show }
      it { expect(response).to redirect_to('/users/sign_in') }
    end
    context "authenticated user" do
      before do
        sign_in current_user
        get :show
      end
      context "non-admin" do
        let(:current_user) { create(:user) }
        it { expect(response).to be_unauthorized }
      end
      context "platform admin" do
        let(:current_user) { create(:platform_admin) }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
    end
  end
end
