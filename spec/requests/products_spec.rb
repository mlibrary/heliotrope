# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:product, purchase: 'https://wolverine.umich.edu') }

  before { target }

  describe '#index' do
    subject { get "/products" }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to('/presses?locale=en')
      expect(response).to have_http_status(:found)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to('/presses?locale=en')
        expect(response).to have_http_status(:found)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to('/presses?locale=en')
          expect(response).to have_http_status(:found)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:ok)
          end

          context 'filtering' do
            subject { get "/products?identifier_like=#{target.identifier}" }

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

  describe '#show' do
    subject { get "/products/#{target.id}" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:show)
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end

  describe '#new' do
    subject { get "/products/new" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:new)
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end

  describe '#edit' do
    subject { get "/products/#{target.id}/edit" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:edit)
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end

  describe '#create' do
    subject { post "/products", params: { product: product_params } }

    let(:product_params) { { identifier: 'identifier', name: 'name' } }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(product_path(Product.find_by(product_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid product params' do
            let(:product_params) { { identifier: '', name: 'name' } }

            it do
              expect { subject }.not_to raise_error
              expect(response).to render_template(:new)
              expect(response).to have_http_status(:ok)
            end
          end
        end
      end
    end
  end

  describe '#update' do
    subject { put "/products/#{target.id}", params: { product: product_params } }

    let(:product_params) { { identifier: 'identifier', name: 'name' } }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(product_path(Product.find_by(product_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid product params' do
            let(:product_params) { { identifier: '', name: 'name' } }

            it do
              expect { subject }.not_to raise_error
              expect(response).to render_template(:edit)
              expect(response).to have_http_status(:ok)
            end
          end
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete "/products/#{target.id}" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.to raise_error(ActionController::RoutingError)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(products_path)
            expect(response).to have_http_status(:found)
            expect { Product.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end

  describe "Components Products" do
    let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
    let(:product) { create(:product) }
    let(:component) { create(:component) }
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

  describe '#purchase' do
    subject { get "/products/#{target.id}/purchase" }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to(target.purchase)
      expect(response).to have_http_status(:found)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to(target.purchase)
        expect(response).to have_http_status(:found)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to(target.purchase)
          expect(response).to have_http_status(:found)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(target.purchase)
            expect(response).to have_http_status(:found)
          end
        end
      end
    end
  end
end
