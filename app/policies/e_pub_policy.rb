# frozen_string_literal: true

class EPubPolicy
  def initialize(current_user, current_institutions, e_pub_id)
    @actor = { email: current_user&.email, institutions: current_institutions }
    @component = Component.find_by(handle: HandleService.path(e_pub_id)) # An EPub is "Restricted" if it exist in the components table.
  end

  def authorize!(action, message = nil)
    return if action_granted?(action)
    return if action_permitted?(action)
    raise(NotAuthorizedError, message)
  end

  private

    def action_granted?(action)
      case action
      when :show
        component.blank? # By default all EPubs are "Open Access", in other words, an EPub is "Restricted" only if it exist in the components table.
      else
        false # implicit rejection
      end
    end

    def action_permitted?(action)
      Checkpoint::Query::ActionPermitted.new(actor, action, component, authority: authority).true?
    rescue StandardError => e
      Rails.logger.error "EPubPolicy::action_permitted?(#{action}) #{e}"
      false
    end

    def authority
      @authority ||= Checkpoint::Authority.new(agent_resolver: ActorAgentResolver.new, resource_resolver: ComponentResourceResolver.new)
    end

    attr_reader :actor, :component
end
