# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  context 'anonymous' do
    describe "PUT /users/:id/tokenize" do
      it do
        expect { put tokenize_user_path(user.id) }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "PUT /users/:id/tokenize" do
        it do
          expect { put tokenize_user_path(user.id) }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "PUT /users/:id/tokenize" do
        it do
          put tokenize_user_path(user.id)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(partial_fulcrum_path(:tokens))
        end
      end
    end
  end
end
