# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees", type: :request do
  let(:lessee) { create(:lessee) }

  context 'anonymous' do
    describe "GET /lessees" do
      it do
        get lessees_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /lessees" do
        it do
          get lessees_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /lessees" do
        it do
          get lessees_path
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end
    end
  end
end
