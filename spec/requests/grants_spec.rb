# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Grants", type: :request do
  let(:grant) { create(:grant) }

  context 'anonymous' do
    describe "GET /grants" do
      it do
        get grants_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /grants" do
        it do
          get grants_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /grants" do
        it do
          get grants_path
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end

        context 'filtering' do
          subject { get "/grants?resource_type=Product" }

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
