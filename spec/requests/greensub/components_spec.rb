# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Greensub::Components", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:component, identifier: noid, name: noid,  noid: noid) }
  let(:noid) { 'validnoid' }
  let(:file_set) { double('file_set', id: noid, parent: monograph) }
  let(:monograph) { double('monograph', id: noid) }

  before do
    allow(FileSet).to receive(:find).with(noid).and_return(file_set)
    allow(Monograph).to receive(:find).with(noid).and_return(monograph)
    target
  end

  describe '#index' do
    subject { get greensub_components_path }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:ok)
          end

          context 'filtering' do
            subject { get greensub_components_path, params: "identifier_like=#{target.identifier}" }

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
    subject { get greensub_component_path(target.id) }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

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
    subject { get new_greensub_component_path }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

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
    subject { get edit_greensub_component_path(target.id) }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

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
    subject { post greensub_components_path, params: { greensub_component: component_params } }

    let(:component_params) { { identifier: new_noid, name: new_noid, noid: new_noid } }
    let(:new_noid) { 'noid_noid' }
    let(:new_monograph) { double('monograph', id: new_noid, update_index: true) }

    before do
      allow(Monograph).to receive(:find).with(new_noid).and_return(new_monograph)
    end

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(greensub_component_path(Greensub::Component.find_by(component_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid component params' do
            let(:component_params) { { identifier: '', noid: '' } }

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
    subject { put greensub_component_path(target.id), params: { greensub_component: component_params } }

    let(:component_params) { { identifier: 'identifier', name: noid, noid: noid } }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(greensub_component_path(Greensub::Component.find_by(component_params)))
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
    subject { delete greensub_component_path(target.id) }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to redirect_to(greensub_components_path)
            expect(response).to have_http_status(:found)
            expect { Greensub::Component.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end

  describe "Products Components" do
    let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
    let(:product) { create(:product) }
    let(:component) { create(:component) }
    let(:post_component) { post greensub_product_components_path(product.id), params: { id: component.id } }
    let(:delete_component) { delete greensub_product_component_path(product.id, component.id) }

    let(:new_monograph) { double('monograph', id: component.noid, update_index: true) }

    before do
      allow(Monograph).to receive(:find).with(component.noid).and_return(new_monograph)
    end

    it do
      expect(component.products.count).to eq 0
      expect(product.components.count).to eq 0
      expect { post_component }.to raise_error(ActionController::RoutingError)
      expect { delete_component }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

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
