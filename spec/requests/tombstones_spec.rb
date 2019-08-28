# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Tombstones", type: :request do
  context 'anonymous' do
    describe "GET /tombstones" do
      it do
        get tombstones_path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'user' do
    before { sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /tombstones" do
        it do
          get tombstones_path
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /tombstones" do
        it do
          get tombstones_path
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end
    end
  end
end
