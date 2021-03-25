# frozen_string_literal: true

module AbilityHelpers
  protected

    def can?(action, agent: actor, resource: target)
      # NOTE: Sighrax methods are Incognito aware.
      return true if Sighrax.platform_admin?(agent)

      Sighrax.ability_can?(agent, action, resource)
    end
end
