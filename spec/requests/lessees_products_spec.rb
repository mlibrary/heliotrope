# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees Products", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:product) { create(:product) }
  let(:lessee) { create(:lessee) }

  context '/lessees/:lessee_id/products/:id' do
    let(:post_product) { post "/lessees/#{lessee.id}/products", params: { id: product.id } }
    let(:delete_product) { delete "/lessees/#{lessee.id}/products/#{product.id}" }

    it do
      expect(lessee.products.count).to eq 0
      expect(product.lessees.count).to eq 0
      expect { post_product }.to raise_error(ActionController::RoutingError)
      expect { delete_product }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { post_product }.to raise_error(ActionController::RoutingError)
        expect { delete_product }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { post_product }.to raise_error(ActionController::RoutingError)
          expect { delete_product }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { post_product }.not_to raise_error
            expect(lessee.products.count).to eq 1
            expect(product.lessees.count).to eq 1
            expect { delete_product }.not_to raise_error
            expect(lessee.products.count).to eq 0
            expect(product.lessees.count).to eq 0
          end
        end
      end
    end
  end

  context '/products/:product_id/lessees/:id' do
    let(:post_lessee) { post "/products/#{product.id}/lessees", params: { id: lessee.id } }
    let(:delete_lessee) { delete "/products/#{product.id}/lessees/#{lessee.id}" }

    it do
      expect(lessee.products.count).to eq 0
      expect(product.lessees.count).to eq 0
      expect { post_lessee }.to raise_error(ActionController::RoutingError)
      expect { delete_lessee }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { post_lessee }.to raise_error(ActionController::RoutingError)
        expect { delete_lessee }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { post_lessee }.to raise_error(ActionController::RoutingError)
          expect { delete_lessee }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { post_lessee }.not_to raise_error
            expect(lessee.products.count).to eq 1
            expect(product.lessees.count).to eq 1
            expect { delete_lessee }.not_to raise_error
            expect(lessee.products.count).to eq 0
            expect(product.lessees.count).to eq 0
          end
        end
      end
    end
  end
end
