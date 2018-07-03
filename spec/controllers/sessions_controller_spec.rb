# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe '#new' do
    subject { get :new }

    context 'user signed in' do
      before { allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(true) }

      it do
        is_expected.to redirect_to 'http://test.host/dashboard?locale=en'
        expect(cookies[:fulcrum_signed_in_static]).not_to be nil
      end

      context 'stored location for user' do
        before { allow_any_instance_of(SessionsController).to receive(:stored_location_for).with(:user).and_return('http://return_to_me') }

        it { is_expected.to redirect_to 'http://return_to_me' }
      end
    end

    context 'user not signed in' do
      before { allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(false) }

      it { is_expected.to redirect_to new_authentications_path }
    end
  end

  describe '#destroy' do
    subject { get :destroy }

    let(:cookie) { "cosign-" + Hyrax::Engine.config.hostname }

    before do
      cookies[cookie] = true
      cookies[:fulcrum_signed_in_static] = true
      allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(true)
    end

    it do
      expect(ENV).to receive(:[]=).with('FAKE_HTTP_X_REMOTE_USER', '(null)')
      is_expected.to redirect_to root_url
      expect(cookies[:fulcrum_signed_in_static]).to be nil
      expect(cookies[cookie]).to be nil
    end
  end
end
