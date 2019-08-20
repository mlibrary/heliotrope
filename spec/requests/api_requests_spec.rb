# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "APIRequests", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:api_request) }

  before { target }

  describe '#index' do
    subject { get "/api_requests" }

    it do
      expect { subject }.not_to raise_error
      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:found)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to redirect_to(root_path)
        expect(response).to have_http_status(:found)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to redirect_to(root_path)
          expect(response).to have_http_status(:found)
        end

        context 'platform administrator' do
          let(:current_user) { create(:platform_admin) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end

  describe '#show' do
    subject { get "/api_requests/#{target.id}" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

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

  describe '#truncate' do
    subject { delete "/api_requests/truncate" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

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
            expect(response).to redirect_to(api_requests_path)
            expect(response).to have_http_status(:found)
            expect(APIRequest.count).to eq(1)
          end
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete "/api_requests/#{target.id}" }

    it do
      expect { subject }.to raise_error(ActionController::RoutingError)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

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
            expect(response).to redirect_to(api_requests_path)
            expect(response).to have_http_status(:found)
            expect { Greensub::Product.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
