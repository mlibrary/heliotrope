# frozen_string_literal: true

class EPubPolicy
  def initialize(actor, target)
    @actor = actor
    @target = target
  end

  def authorize!(action, message = nil)
    return if action_permitted?(action)
    raise(NotAuthorizedError, message)
  end

  def show?
    # return true if open_access?(target)
    action_permitted?(:read)
  end

  private

    def action_permitted?(action)
      Checkpoint::Query::ActionPermitted.new(actor, action, target, authority: authority).true?
    rescue StandardError => e
      Rails.logger.error "EPubPolicy::action_permitted?(#{action}) #{e}"
      false
    end

    def authority
      Services.checkpoint
    end

    attr_reader :actor, :target
end
