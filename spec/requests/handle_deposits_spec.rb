# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "HandleDeposits", type: :request do
  let(:current_user) { User.guest(user_key: 'wolverine@umich.edu') }
  let(:target) { create(:handle_deposit) }

  before { target }

  describe '#index' do
    subject { get "/aptrust_deposits" }

    it do
      expect { subject }.not_to raise_error
      expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
      expect(response).to have_http_status(:not_found)
    end

    context 'authenticated' do
      before { sign_in(current_user) }

      it do
        expect { subject }.not_to raise_error
        expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
        expect(response).to have_http_status(:not_found)
      end

      context 'authorized' do
        before { allow_any_instance_of(ApplicationController).to receive(:authorize!) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
          expect(response).to have_http_status(:not_found)
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
end
