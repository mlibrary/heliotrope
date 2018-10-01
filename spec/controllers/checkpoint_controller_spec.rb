# frozen_string_literal: true

require 'rails_helper'

describe CheckpointController do
  context 'rescue_from exception' do
    controller do
      attr_accessor :the_exception
      def trigger
        raise @the_exception
      end
    end

    before { routes.draw { get "trigger" => "checkpoint#trigger" } }

    it "CanCan::AccessDenied with response unauthorized" do
      controller.the_exception = CanCan::AccessDenied.new
      get :trigger
      expect(response).to be_unauthorized
    end

    it "NotAuthorizedError with response unauthorized" do
      controller.the_exception = NotAuthorizedError.new
      get :trigger
      expect(response).to be_unauthorized
    end
  end

  describe '#current_ability' do
    it { expect(controller.current_ability).to be_a(AbilityCheckpoint) }
  end

  describe '#checkpoint_controller?' do
    it { expect(controller.send(:checkpoint_controller?)).to be true }
  end
end
