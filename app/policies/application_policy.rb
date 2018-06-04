# frozen_string_literal: true

class ApplicationPolicy
  def initialize(current_user, resource_class, resource)
    @current_user = current_user
    @resource_class = resource_class
    @resource = resource
  end

  def authorize!(action, message = nil)
    raise(NotActionError, action.to_s) unless action.to_s.end_with?('?')
    return if @current_user.platform_admin?
    return if public_send(action)
    return if action_permitted?(action.to_s.chomp('?').to_sym)
    raise(NotAuthorizedError, message)
  end

  def method_missing(sym, *args, &block)
    return false if sym.to_s.end_with?('?')
    super
  end

  def respond_to_missing?(sym, include_private = false)
    sym.to_s.end_with?('?') || super
  end

  protected

    def action_permitted?(action, agent: PolicyAgent.new(User, @current_user), target: PolicyResource.new(@resource_class, @resource))
      Checkpoint::Query::ActionPermitted.new(agent, action, target, authority: authority).true?
    end

    def authority
      Services.checkpoint
    end
end
