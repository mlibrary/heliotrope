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
    before { cosign_sign_in(current_user) }

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

      context 'lessees' do
        let(:product) { create(:product) }
        let(:individual) { create(:individual) }
        let(:institution) { create(:institution) }

        before { PermissionService.clear_permits_table }

        it do
          expect(Grant.count).to be_zero
          expect(product.lessees.count).to be_zero
          expect(product.lessees).to be_empty

          post "/grants", params: { grant: {
            agent_type: 'Individual',
            agent_id: individual.id,
            credential_type: 'permission',
            credential_id: 'read',
            resource_type: 'Product',
            resource_id: product.id
          } }
          product.reload
          expect(Grant.count).to eq(1)
          expect(product.lessees.count).to eq(1)
          expect(product.lessees).to match_array([individual.lessee])

          post "/grants", params: { grant: {
            agent_type: 'Individual',
            agent_id: individual.id,
            credential_type: 'permission',
            credential_id: 'read',
            resource_type: 'Product',
            resource_id: product.id
          } }
          product.reload
          expect(Grant.count).to eq(1)
          expect(product.lessees.count).to eq(1)
          expect(product.lessees).to match_array([individual.lessee])

          post "/grants", params: { grant: {
            agent_type: 'Institution',
            agent_id: institution.id,
            credential_type: 'permission',
            credential_id: 'read',
            resource_type: 'Product',
            resource_id: product.id
          } }
          product.reload
          expect(Grant.count).to eq(2)
          expect(product.lessees.count).to eq(2)
          expect(product.lessees).to match_array([individual.lessee, institution.lessee])

          post "/grants", params: { grant: {
            agent_type: 'Institution',
            agent_id: institution.id,
            credential_type: 'permission',
            credential_id: 'read',
            resource_type: 'Product',
            resource_id: product.id
          } }
          product.reload
          expect(Grant.count).to eq(2)
          expect(product.lessees.count).to eq(2)
          expect(product.lessees).to match_array([individual.lessee, institution.lessee])

          delete "/grants/#{Grant.last.id}"
          product.reload
          expect(Grant.count).to eq(1)
          expect(product.lessees.count).to eq(1)
          expect(product.lessees).to match_array([individual.lessee])

          delete "/grants/#{Grant.last.id}"
          product.reload
          expect(Grant.count).to be_zero
          expect(product.lessees.count).to be_zero
          expect(product.lessees).to be_empty
        end
      end
    end
  end
end
