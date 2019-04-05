# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Greensub::Institutions", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:institution) }

  before { target }

  describe '#index' do
    subject { get greensub_institutions_path }

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
            subject { get greensub_institutions_path, params: "identifier_like#{target.identifier}" }

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
    subject { get greensub_institution_path(target.id) }

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
    subject { get new_greensub_institution_path }

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
    subject { get edit_greensub_institution_path(target.id) }

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
    subject { post greensub_institutions_path, params: { greensub_institution: institution_params } }

    let(:institution_params) { { identifier: 'identifier', name: 'name' } }

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
            expect(response).to redirect_to(greensub_institution_path(Greensub::Institution.find_by(institution_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid institution params' do
            let(:institution_params) { { identifier: '', name: 'name' } }

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
    subject { put greensub_institution_path(target.id), params: { greensub_institution: institution_params } }

    let(:institution_params) { { name: 'new_name' } }

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
            expect(response).to redirect_to(greensub_institution_path(Greensub::Institution.find(target.id)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid institution params' do
            let(:institution_params) { { identifier: 'identifier' } }

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
    subject { delete greensub_institution_path(target.id) }

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
            expect(response).to redirect_to(greensub_institutions_path)
            expect(response).to have_http_status(:found)
            expect { Greensub::Institution.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
