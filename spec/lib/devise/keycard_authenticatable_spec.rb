# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/ExpectInHook
RSpec.describe Devise::Strategies::KeycardAuthenticatable do
  let(:strategy) { described_class.new(nil) }

  before do
    allow(strategy).to receive(:identity).and_return(identity)
  end

  context "with a user_eid" do
    let(:user_eid) { 'user@domain' }
    let(:identity) { { user_eid: user_eid } }

    context "for an existing user" do
      let(:user) { double('User') }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:identity=).with(identity)
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
          expect(new_user).to receive(:populate_attributes).once
          expect(Guest).to receive(:new).never
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
          expect(guest).to receive(:populate_attributes).once
          expect(User).to receive(:new).never
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
  end

  context "without a user_eid" do
    let(:identity) { {} }

    it "passes on authenticating" do
      expect(strategy).to receive(:pass)
      strategy.authenticate!
    end
  end
end
# rubocop:enable RSpec/ExpectInHook
