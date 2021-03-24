# frozen_string_literal: true

module AbilityHelpers
  protected

    def can?(action, agent: actor, resource: target)
      # CRUD - create, read, update, and delete
      raise ArgumentError unless ValidationService.valid_action?(action)

      # Sighrax methods are Incognito aware.
      return true if Sighrax.platform_admin?(agent)

      # CanCanCan expects :destroy action instead of :delete action
      # This is because ActiveRecord's delete method does NOT call callbacks
      # while ActiveRecord's destroy method does call callbacks.
      # Also, Rails controllers receive action :destroy instead of action :delelte
      # hence CanCanCan and Rails are rogues.
      action = :destroy if action == :delete
      Sighrax.ability_can?(agent, action, resource)
    end
end
