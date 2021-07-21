# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Greensub::InstitutionAffiliations", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:institution_affiliation) }

  before { target }

  describe '#index' do
    subject { get greensub_institution_affiliations_path }

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
            subject { get greensub_institution_affiliations_path, params: "dlps_institution_id_like#{target.dlps_institution_id}" }

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
    subject { get greensub_institution_affiliation_path(target.id) }

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
    subject { get new_greensub_institution_affiliation_path }

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
    subject { get edit_greensub_institution_affiliation_path(target.id) }

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
    subject { post greensub_institution_affiliations_path, params: { greensub_institution_affiliation: institution_affiliation_params } }

    let(:institution_affiliation_params) { { institution_id: target.institution.id, dlps_institution_id: target.dlps_institution_id + 1, affiliation: 'alum' } }

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
            expect(response).to redirect_to(greensub_institution_affiliation_path(Greensub::InstitutionAffiliation.find_by(institution_affiliation_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid institution affiliation params' do
            let(:institution_affiliation_params) { { affiliation: 'affiliation' } }

            it do
              expect { subject }.not_to raise_error
              expect(response).to render_template(:new)
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end
        end
      end
    end
  end

  describe '#update' do
    subject { put greensub_institution_affiliation_path(target.id), params: { greensub_institution_affiliation: institution_affiliation_params } }

    let(:institution_affiliation_params) { { affiliation: 'alum' } }

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
            expect(response).to redirect_to(greensub_institution_affiliation_path(Greensub::InstitutionAffiliation.find(target.id)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid institution affiliation params' do
            let(:institution_affiliation_params) { { affiliation: 'affiliation' } }

            it do
              expect { subject }.not_to raise_error
              expect(response).to render_template(:edit)
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete greensub_institution_affiliation_path(target.id) }

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
            expect(response).to redirect_to(greensub_institution_affiliations_path)
            expect(response).to have_http_status(:found)
            expect { Greensub::InstitutionAffiliation.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
