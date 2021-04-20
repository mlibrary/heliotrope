# frozen_string_literal: true

module AbilityHelpers
  protected

    def can?(action, agent: actor, resource: target) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # CRUD - create, read, update, and delete
      raise ArgumentError unless ValidationService.valid_action?(action)

      # Sighrax.platform_admin? is Incognito aware.
      return true if Sighrax.platform_admin?(agent)

      press = resource.publisher.press
      return false unless Sighrax.press_role?(actor, press)

      case action
      when :create
        Sighrax.press_admin?(agent, press) ||
          Sighrax.press_editor?(agent, press)
      when :read
        Sighrax.press_admin?(agent, press) ||
          Sighrax.press_editor?(agent, press) ||
            Sighrax.press_analyst?(agent, press)
      when :update
        Sighrax.press_admin?(agent, press) ||
          Sighrax.press_editor?(agent, press)
      when :delete
        Sighrax.press_admin?(agent, press) ||
          Sighrax.press_editor?(agent, press)
      else
        false
      end
    end
end
