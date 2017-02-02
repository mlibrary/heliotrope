require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe "GET #index" do
    context 'unauthenticated user' do
      before do
        get :index
      end
      it { expect(response).to redirect_to new_user_session_path }
    end
    context "authenticated user" do
      let(:user) { create :user }
      before do
        sign_in user
        get :index
      end
      it { expect(response).to_not be_unauthorized }
      it { expect(response).to be_success }
    end
  end
end
