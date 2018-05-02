# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Groupings", type: :request do
  let(:grouping) { create(:grouping) }

  context 'anonymous' do
    describe "GET /groupings" do
      it do
        get groupings_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /groupings" do
        it do
          get groupings_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /groupings" do
        it do
          get groupings_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
