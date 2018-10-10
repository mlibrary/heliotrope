# frozen_string_literal: true

class EPubPolicy
  def initialize(current_user, current_institutions, e_pub_id)
    @actor = { email: current_user&.email, institutions: current_institutions }
    @target = { noid: e_pub_id, products: Component.find_by(handle: HandleService.path(e_pub_id))&.products }
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
      @authority ||= Checkpoint::Authority.new(agent_resolver: ActorAgentResolver.new, resource_resolver: TargetResourceResolver.new)
    end

    attr_reader :actor, :target
end
