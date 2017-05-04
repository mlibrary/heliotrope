# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobsController, type: :controller do
  describe '#forbid' do
    context 'when user is not logged in' do
      it 'denies access' do
        get :forbid
        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'when a non-authorized user is logged in' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'renders 404' do
        expect(controller).to receive(:render_404) { controller.render nothing: true }
        get :forbid
      end
    end
  end
end
