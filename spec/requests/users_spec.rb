# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:user) }

  before { target }

  describe '#index' do
    subject { get users_path }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to('/')
      expect(response).to have_http_status(:moved_permanently)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to('/')
        expect(response).to have_http_status(:moved_permanently)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to('/')
          expect(response).to have_http_status(:moved_permanently)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:ok)
          end

          context 'filtering' do
            subject { get users_path, params: { identifier_like: target.identifier } }

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
    subject { get user_path(target) }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to('/')
      expect(response).to have_http_status(:moved_permanently)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to('/')
        expect(response).to have_http_status(:moved_permanently)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to('/')
          expect(response).to have_http_status(:moved_permanently)
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
    subject { get "/users/new" }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to('/')
      expect(response).to have_http_status(:moved_permanently)
    end

    context 'authenticated' do
      before { cosign_sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to('/')
        expect(response).to have_http_status(:moved_permanently)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to('/')
          expect(response).to have_http_status(:moved_permanently)
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
    subject { get "/users/#{target.id}/edit" }

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
    subject { post "/users", params: { user: user_params } }

    let(:user_params) { { email: 'alumni@umich.edu' } }

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
            expect(response).to redirect_to(user_path(User.find_by(user_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid user params' do
            let(:user_params) { { email: '' } }

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
    subject { put "/users/#{target.id}", params: { user: user_params } }

    let(:user_params) { { email: 'alumni@umich.edu' } }

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
            expect(response).to redirect_to(user_path(User.find_by(user_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid user params' do
            let(:user_params) { { email: '' } }

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
    subject { delete "/users/#{target.id}" }

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
            expect(response).to redirect_to(users_path)
            expect(response).to have_http_status(:found)
            expect { User.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end

  describe '#tokenize' do
    subject { put "/users/#{target.id}/tokenize" }

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
            expect(response).to redirect_to(fulcrum_partials_path(:tokens))
            expect(response).to have_http_status(:found)
          end
        end
      end
    end
  end
end
