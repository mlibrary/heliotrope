# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Manifest", type: :request do
  let(:monograph) { create(:monograph) }

  context 'anonymous' do
    describe "GET /concern/monographs/:id/manifest" do
      it do
        expect { get monograph_manifests_path(monograph) }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /concern/monographs/:id/manifest" do
        it do
          expect { get monograph_manifests_path(monograph) }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /concern/monographs/:id/manifest" do
        it do
          get monograph_manifests_path(monograph)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
