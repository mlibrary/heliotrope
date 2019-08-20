# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AptrustDeposits", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:aptrust_deposit) }

  before { target }

  describe '#index' do
    subject { get "/aptrust_deposits" }

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

  describe '#destroy' do
    subject { delete "/aptrust_deposits/#{target.id}" }

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
            expect(response).to redirect_to(aptrust_deposits_path)
            expect(response).to have_http_status(:found)
          end
        end
      end
    end
  end
end
