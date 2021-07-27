# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Greensub::Licenses", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:full_license, licensee: individual, product: product) }
  let(:individual) { create(:individual) }
  let(:product) { create(:product) }

  before { target }

  describe '#index' do
    subject { get greensub_licenses_path }

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
            subject { get greensub_licenses_path, params: "type_like=Full" }

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
    subject { get greensub_license_path(target.id) }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it { expect { subject }.to raise_error(ActionController::RoutingError) }
        end
      end
    end
  end

  describe '#new' do
    subject { get new_greensub_license_path }

    it { expect { subject }.to raise_error(NameError) }
  end

  describe '#edit' do
    subject { get edit_greensub_license_path(target.id) }

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
    subject { post greensub_licenses_path, params: { greensub_license: license_params } }

    let(:license_params) { { type: 'Greensub::FullLicense' } }

    it { expect { subject }.to raise_error(ActionController::RoutingError) }

    context 'authenticated' do
      before { sign_in(current_user) }

      it { expect { subject }.to raise_error(ActionController::RoutingError) }

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it { expect { subject }.to raise_error(ActionController::RoutingError) }

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it { expect { subject }.to raise_error(ActionController::RoutingError) }

          context 'invalid license params' do
            let(:license_params) { { type: 'license_type' } }

            it { expect { subject }.to raise_error(ActionController::RoutingError) }
          end
        end
      end
    end
  end

  describe '#update' do
    subject { put greensub_license_path(target.id), params: { greensub_license: license_params } }

    let(:license_params) { { type: 'Greensub::ReadLicense' } }

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
            expect(response).to redirect_to(greensub_licenses_path)
            expect(response).to have_http_status(:found)
          end

          context 'invalid license params' do
            let(:license_params) { { type: 'ReadLicense' } }

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
    subject { delete greensub_license_path(target.id) }

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
            expect(response).to redirect_to(greensub_licenses_path)
            expect(response).to have_http_status(:found)
            expect { Greensub::License.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end

          context 'grant' do
            before do
              clear_grants_table
              Authority.grant!(create(:individual), target, create(:product))
            end

            it do
              expect { subject }.not_to raise_error
              expect(response).to redirect_to(greensub_licenses_path)
              expect(response).to have_http_status(:found)
              expect { Greensub::License.find(target.id) }.not_to raise_error
            end
          end
        end
      end
    end
  end
end
