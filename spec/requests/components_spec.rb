# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
  let(:component) { create(:component) }

  context 'anonymous' do
    describe "GET /components" do
      it do
        get components_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /components" do
        it do
          get components_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /components" do
        it do
          get components_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
