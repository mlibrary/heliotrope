# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components Products", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:product) { create(:product) }
  let(:component) { create(:component) }

  context '/components/:component_id/products/:id' do
    let(:post_product) { post "/components/#{component.id}/products", params: { id: product.id } }
    let(:delete_product) { delete "/components/#{component.id}/products/#{product.id}" }

    it do
      expect(component.products.count).to eq 0
      expect(product.components.count).to eq 0
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
            expect(component.products.count).to eq 1
            expect(product.components.count).to eq 1
            expect { delete_product }.not_to raise_error
            expect(component.products.count).to eq 0
            expect(product.components.count).to eq 0
          end
        end
      end
    end
  end

  context '/products/:product_id/components/:id' do
    let(:post_component) { post "/products/#{product.id}/components", params: { id: component.id } }
    let(:delete_component) { delete "/products/#{product.id}/components/#{component.id}" }

    it do
      expect(component.products.count).to eq 0
      expect(product.components.count).to eq 0
      expect { post_component }.to raise_error(ActionController::RoutingError)
      expect { delete_component }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { post_component }.to raise_error(ActionController::RoutingError)
        expect { delete_component }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { post_component }.to raise_error(ActionController::RoutingError)
          expect { delete_component }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { post_component }.not_to raise_error
            expect(component.products.count).to eq 1
            expect(product.components.count).to eq 1
            expect { delete_component }.not_to raise_error
            expect(component.products.count).to eq 0
            expect(product.components.count).to eq 0
          end
        end
      end
    end
  end
end
