# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Institutions", type: :request do
  let(:institution) { create(:institution) }

  context 'anonymous' do
    describe "GET /institutions" do
      it do
        get institutions_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end

    describe "GET /institutions/:id/login" do
      it do
        get login_institution_path(institution)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(institution.login)
      end
    end

    describe "GET /institutions/:id/help" do
      it do
        get help_institution_path(institution)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /institutions" do
        it do
          get institutions_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end

      describe "GET /institutions/:id/login" do
        it do
          get login_institution_path(institution)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(institution.login)
        end
      end

      describe "GET /institutions/:id/help" do
        it do
          get help_institution_path(institution)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /institutions" do
        it do
          get institutions_path
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /institutions/:id/login" do
        it do
          get login_institution_path(institution)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(institution.login)
        end
      end

      describe "GET /institutions/:id/help" do
        it do
          get help_institution_path(institution)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
