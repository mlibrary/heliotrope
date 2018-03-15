# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  context 'unauthorized' do
    describe "GET /products" do
      it "works! (now write some real specs)" do
        get products_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'authorized' do
    let(:user) { create(:platform_admin) }

    before { cosign_sign_in(user) }

    describe "GET /products" do
      it "works! (now write some real specs)" do
        get products_path
        expect(response).to have_http_status(200)
      end
    end
  end
end
