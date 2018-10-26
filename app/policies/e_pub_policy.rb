# frozen_string_literal: true

class EPubPolicy
  def initialize(current_user, current_institutions, e_pub_id)
    @actor = { user: current_user, institutions: current_institutions }
    @target = { noid: e_pub_id }
  end

  def authorize!(action, message = nil)
    return if action_permitted?(action)
    raise(NotAuthorizedError, message)
  end

  def show?
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
