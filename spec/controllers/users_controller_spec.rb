# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe "PUT #tokenize" do
    let(:user_id) { create(:user).id }

    context 'unauthenticated user' do
      before { put :tokenize, params: { id: user_id } }

      it { expect(response).to redirect_to('/login') }
    end

    context "authenticated user" do
      let(:current_user) { create(:user) }

      before do
        cosign_sign_in current_user
        put :tokenize, params: { id: user_id }
      end

      it { expect(response).to be_unauthorized }

      context "current user is platform admin" do
        let(:current_user) { create(:platform_admin) }

        it { expect(response).to redirect_to('/fulcrum/tokens?locale=en') }
      end
    end
  end
end
