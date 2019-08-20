# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Customers", type: :request do
  context 'anonymous' do
    describe "GET /customers" do
      it do
        get customers_path
        expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'user' do
    before { sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /customers" do
        it do
          get customers_path
          expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /customers" do
        it do
          get customers_path
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
