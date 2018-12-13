# frozen_string_literal: true

module Incognito
  class << self
    def allow_all(actor)
      return true if short_circuit?(actor)
      actor.sign_in_count = 0
      actor.save
      true
    end

    def allow_platform_admin?(actor)
      return true if short_circuit?(actor)
      (actor.sign_in_count & 1).zero?
    end

    def allow_platform_admin(actor, value = true)
      return true if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count & ~1 : actor.sign_in_count | 1
      actor.save
      allow_platform_admin?(actor)
    end

    def allow_hyrax_can?(actor)
      return true if short_circuit?(actor)
      (actor.sign_in_count & 2).zero?
    end

    def allow_hyrax_can(actor, value = true)
      return true if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count & ~2 : actor.sign_in_count | 2
      actor.save
      allow_hyrax_can?(actor)
    end

    def allow_action_permitted?(actor)
      return true if short_circuit?(actor)
      (actor.sign_in_count & 4).zero?
    end

    def allow_action_permitted(actor, value = true)
      return true if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count & ~4 : actor.sign_in_count | 4
      actor.save
      allow_action_permitted?(actor)
    end

    private

      def short_circuit?(actor)
        !(actor.is_a?(User) && actor.platform_admin?)
      end
  end
end
