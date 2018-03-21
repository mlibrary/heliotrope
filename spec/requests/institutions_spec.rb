# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Institutions", type: :request do
  let(:institution) { create(:institution) }

  context 'unauthorized' do
    describe "GET /institutions" do
      it do
        get institutions_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(presses_path)
      end
    end
    describe "GET /institutions/1/login" do
      it do
        get login_institution_path(institution)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(institution.login)
      end
    end
    describe "GET /institutions/1/help" do
      it do
        get help_institution_path(institution)
        expect(response).to have_http_status(200)
      end
    end
  end

  context 'authorized' do
    let(:user) { create(:platform_admin) }

    before { cosign_sign_in(user) }

    describe "GET /institutions" do
      it do
        get institutions_path
        expect(response).to have_http_status(200)
      end
    end
    describe "GET /institutions/1/login" do
      it do
        get login_institution_path(institution)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(institution.login)
      end
    end
    describe "GET /institutions/1/help" do
      it do
        get help_institution_path(institution)
        expect(response).to have_http_status(200)
      end
    end
  end
end
