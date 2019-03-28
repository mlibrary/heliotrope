# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Rants", type: :request do
  let(:rant) { create(:rant) }

  context 'anonymous' do
    describe "GET /rants" do
      it do
        get rants_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /rants" do
        it do
          get rants_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /rants" do
        it do
          get rants_path
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end

        context 'filtering' do
          subject { get "/rants?resource_type=Product" }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end
end
