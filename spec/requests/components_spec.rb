# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:component, identifier: noid, name: noid,  noid: noid, handle: HandleService.path(noid)) }
  let(:noid) { 'validnoid' }
  let(:file_set) { double('file_set', id: noid, parent: monograph) }
  let(:monograph) { double('monograph', id: noid) }

  before do
    allow(FileSet).to receive(:find).with(noid).and_return(file_set)
    allow(Monograph).to receive(:find).with(noid).and_return(monograph)
    target
  end

  describe '#index' do
    subject { get "/components" }

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
            subject { get "/components?identifier_like=#{target.identifier}" }

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
    subject { get "/components/#{target.id}" }

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
    subject { get "/components/new" }

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
    subject { get "/components/#{target.id}/edit" }

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
    subject { post "/components", params: { component: component_params } }

    let(:component_params) { { identifier: new_noid, name: new_noid, noid: new_noid, handle: HandleService.path(new_noid) } }
    let(:new_noid) { 'noid_noid' }

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
            expect(response).to redirect_to(component_path(Component.find_by(component_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid component params' do
            let(:component_params) { { identifier: '', noid: '', handle: '' } }

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
    subject { put "/components/#{target.id}", params: { component: component_params } }

    let(:component_params) { { identifier: 'identifier', name: noid, noid: noid, handle: HandleService.path(noid) } }

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
            expect(response).to redirect_to(component_path(Component.find_by(component_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid component params' do
            let(:component_params) { { identifier: '', name: '', noid: '', handle: '' } }

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
    subject { delete "/components/#{target.id}" }

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
            expect(response).to redirect_to(components_path)
            expect(response).to have_http_status(:found)
            expect { Component.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end

  describe "Products Components" do
    let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
    let(:product) { create(:product) }
    let(:component) { create(:component) }
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
