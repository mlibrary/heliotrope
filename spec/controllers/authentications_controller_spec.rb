# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthenticationsController, type: :controller do
  describe '#new' do
    subject { get :new }

    it { is_expected.to render_template :new }
  end

  describe '#create' do
    subject { post :create, params: { authentication: { email: 'wolverine@umich.edu' } } }

    it do
      expect(ENV).to receive(:[]=).with('FAKE_HTTP_X_REMOTE_USER', 'wolverine@umich.edu')
      is_expected.to redirect_to new_user_session_path
    end
  end

  describe '#destroy' do
    subject { get :destroy }

    it { is_expected.to redirect_to root_url }

    context 'stored location for user' do
      before { allow_any_instance_of(described_class).to receive(:stored_location_for).with(:user).and_return('http://return_to_me') }

      it { is_expected.to redirect_to 'http://return_to_me' }
    end
  end
end
