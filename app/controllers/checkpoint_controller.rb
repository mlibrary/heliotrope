# frozen_string_literal: true

class CheckpointController < ApplicationController
  skip_authorization_check
  before_action :debug_action_breakpoint
  rescue_from CanCan::AccessDenied, with: :render_unauthorized
  rescue_from NotAuthorizedError, with: :render_unauthorized

  def current_ability
    @current_ability ||= AbilityCheckpoint.new(current_user)
  end

  private

    def checkpoint_controller?
      true # Override of ApplicationController
    end

    def debug_action_breakpoint
      true # set breakpoint here!
    end
end
