# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/ExpectInHook
RSpec.describe Devise::Strategies::KeycardAuthenticatable do
  let(:strategy) { described_class.new(nil) }

  before do
    allow(strategy).to receive(:identity).and_return(identity)
    allow(strategy).to receive(:request_attributes).and_return(request_attributes)
    # The Rack/Warden stuff apparently has a nil env/session...
    # We just purge the log_me_in flag, so do the simplest stub we can.
    allow(strategy).to receive(:session).and_return({})
  end

  context "with a user_eid or identity_provider" do
    let(:identity) { { user_eid: user_eid } }
    let(:user_eid) { 'user@domain' }
    let(:request_attributes) { { identity_provider: identity_provider } }
    let(:identity_provider) { 'https://shibboleth.umich.edu/idp/shibboleth' }

    context "for an existing user" do
      let(:user) { double('User') }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:identity=).with(identity)
        allow(user).to receive(:request_attributes=).with(request_attributes)
      end

      it "authenticates succesfully" do
        expect(strategy.authenticate!).to eq(:success)
      end

      it "sets the current user" do
        strategy.authenticate!
        expect(strategy.user).to eq(user)
      end
    end

    context "for an unknown user" do
      context "when create_user_on_login is enabled" do
        let(:new_user) { User.new(user_key: user_eid) }

        before do
          allow(Rails.configuration).to receive(:create_user_on_login).and_return(true)
          allow(User).to receive(:find_by).and_return(nil)
          expect(User).to receive(:new).with(user_key: user_eid).and_return(new_user)
          expect(Guest).not_to receive(:new)
        end

        it "authenticates succesfully" do
          expect(strategy.authenticate!).to eq(:success)
        end

        it "allocates a new user with the EID and sets it as current" do
          strategy.authenticate!
          expect(strategy.user).to eq(new_user)
        end
      end

      context "when create_user_on_login is disabled" do
        let(:guest) { User.guest(user_key: user_eid) }

        before do
          allow(Rails.configuration).to receive(:create_user_on_login).and_return(false)
          allow(User).to receive(:find_by).and_return(nil)
          expect(Guest).to receive(:new).with(user_key: user_eid).and_return(guest)
          expect(User).not_to receive(:new)
        end

        it "authenticates succesfully" do
          expect(strategy.authenticate!).to eq(:success)
        end

        it "allocates a guest user with the EID and sets it as current" do
          strategy.authenticate!
          expect(strategy.user).to eq(guest)
        end
      end
    end

    context "when user_eid is missing" do
      let(:user_eid) {}
      let(:guest) { User.guest(user_key: "guest@fulcrum.org") }

      before do
        allow(Rails.configuration).to receive(:create_user_on_login).and_return(false)
        allow(User).to receive(:find_by).and_return(nil)
        expect(Guest).to receive(:new).with(user_key: "guest@fulcrum.org").and_return(guest)
        expect(User).not_to receive(:new)
      end

      it "authenticates succesfully" do
        expect(strategy.authenticate!).to eq(:success)
      end

      it "sets the current user" do
        strategy.authenticate!
        expect(strategy.user).to eq(guest)
      end
    end
  end

  context "without a user_eid or identity_provider" do
    let(:identity) { {} }
    let(:request_attributes) { {} }

    it "passes on authenticating" do
      expect(strategy).to receive(:pass)
      strategy.authenticate!
    end
  end
end
# rubocop:enable RSpec/ExpectInHook
