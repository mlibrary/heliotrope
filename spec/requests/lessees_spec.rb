# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:lessee) }

  describe '#index' do
    subject { get "/lessees" }

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
        end
      end
    end
  end

  describe '#show' do
    subject { get "/lessees/#{target.id}" }

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
    subject { get "/lessees/new" }

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
    subject { get "/lessees/#{target.id}/edit" }

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
    subject { post "/lessees", params: { lessee: lessee_params } }

    let(:lessee_params) { { identifier: 'identifier' } }

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
            expect(response).to redirect_to(lessee_path(Lessee.find_by(lessee_params)))
            expect(response).to have_http_status(:found)
          end

          context 'invalid lessee params' do
            let(:lessee_params) { { identifier: '' } }

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

  describe '#delete' do
    subject { delete "/lessees/#{target.id}" }

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
            expect(response).to redirect_to(lessees_path)
            expect(response).to have_http_status(:found)
            expect { Lessee.find(target.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end
end
