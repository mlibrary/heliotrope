# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  let(:product) { create(:product) }

  context 'anonymous' do
    describe "GET /products" do
      it do
        get products_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end

    describe "GET /products/:id/purchase" do
      it do
        get purchase_product_path(product)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(product.purchase)
      end
    end

    describe "GET /products/:id/help" do
      it do
        get help_product_path(product)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /products" do
        it do
          get products_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end

      describe "GET /products/:id/purchase" do
        it do
          get purchase_product_path(product)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(product.purchase)
        end
      end

      describe "GET /products/:id/help" do
        it do
          get help_product_path(product)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /products" do
        it do
          get products_path
          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET /products/:id/purchase" do
        it do
          get purchase_product_path(product)
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(product.purchase)
        end
      end

      describe "GET /products/:id/help" do
        it do
          get help_product_path(product)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
