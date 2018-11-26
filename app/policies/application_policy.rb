# frozen_string_literal: true

class ApplicationPolicy
  def initialize(actor, target)
    @actor = actor
    @target = target
  end

  def authorize!(action, message = nil)
    raise(NotAuthorizedError, message) unless send(action)
  end

  protected

    def action_permitted?(action)
      Checkpoint::Query::ActionPermitted.new(actor, action, target, authority: authority).true?
    rescue StandardError => e
      Rails.logger.error "ApplicationPolicy::action_permitted?(#{action}) #{e}"
      false
    end

    def authority
      Services.checkpoint
    end

    attr_reader :actor, :target
end
