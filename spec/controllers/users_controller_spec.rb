require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe "GET #index" do
    context 'unauthenticated user' do
      before { get :index }
      it { expect(response).to redirect_to new_user_session_path }
    end
    context "authenticated user" do
      before do
        sign_in current_user
        get :index
      end
      context "non-admin" do
        let(:current_user) { create(:user) }
        it { expect(response).to have_http_status(302) }
      end
      context "press admin" do
        let(:current_user) { create(:press_admin, press: create(:press)) }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
      context "platform admin" do
        let(:current_user) { create(:platform_admin) }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
    end
  end

  describe "GET #show" do
    let(:user_id) { 0 }
    context 'unauthenticated user' do
      before { get :show, id: user_id }
      it { expect(response).to redirect_to new_user_session_path }
    end
    context "authenticated user" do
      let(:current_user) { create(:user) }
      before do
        sign_in current_user
        get :show, id: user_id
      end
      context "user record not found" do
        it { expect(response).to be_unauthorized }
      end
      context "current user is user" do
        let(:user_id) { current_user.id }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
      context "current user is different user" do
        let(:user_id) { create(:user).id }
        it { expect(response).to have_http_status(302) }
      end
      context "current user is press admin" do
        let(:current_user) { create(:press_admin, press: create(:press)) }
        let(:user_id) { create(:user).id }
        it { expect(response).to have_http_status(302) }
      end
      context "current user is press admin and user is press editor" do
        let(:current_user) { create(:press_admin, press: press) }
        let(:user_id) { create(:editor, press: press).id }
        let(:press) { create(:press) }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
      context "current user is press admin and user is press editor but different presses" do
        let(:current_user) { create(:press_admin, press: create(:press)) }
        let(:user_id) { create(:editor, press: create(:press)).id }
        it { expect(response).to have_http_status(302) }
      end
      context "current user is platform admin" do
        let(:current_user) { create(:platform_admin) }
        let(:user_id) { create(:user).id }
        it { expect(response).to_not be_unauthorized }
        it { expect(response).to be_success }
      end
    end
  end
end
