# frozen_string_literal: true

# The Incognito Service Module allows platform administrators
# to mask and/or alter their Checkpoint credentials!!!

# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!
# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!
# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!

# The private method short_circuit? returns false when actor is a platform administrator

# actor.sign_in_count bit flags
#   0x01 allow_platform_admin? returns false
#   0x02 allow_ability_can? returns false
#   0x04 allow_action_permitted? returns false
#   0x08 sudo_actor? returns true and ...
#     actor.current_sign_in_ip is substituted for individual_id
#     actor.last_sign_in_ip is substituted for institution_id

# The reset method assigns zero to actor.sign_in_count which nullifies the Incognito affect!!!

# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!
# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!
# WARNING! DO NOT USE THE INCOGNITO SERVICE MODULE!!!

# The Incognito Service Module allows platform administrators
# to mask and/or alter their Checkpoint credentials!!!

# Look under app/policies for usage examples.

module Incognito # rubocop:disable Metrics/ModuleLength
  class << self
    def reset(actor)
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

    def sudo_actor?(actor)
      return false if short_circuit?(actor)
      !(actor.sign_in_count & 8).zero?
    end

    def sudo_actor(actor, value = false, individual_id = 0, institution_affiliation_id = 0)
      return false if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count | 8 : actor.sign_in_count & ~8
      actor.current_sign_in_ip = individual_id
      actor.last_sign_in_ip = institution_affiliation_id
      actor.save
      sudo_actor?(actor)
    end

    def sudo_role?(actor)
      return false if short_circuit?(actor)
      !(actor.sign_in_count & 2).zero?
    end

    def sudo_role(actor, value = false, press_id = 0, press_role = '')
      return false if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count | 2 : actor.sign_in_count & ~2
      actor.department = press_id
      actor.title = press_role
      actor.save
      sudo_role?(actor)
    end

    def developer?(actor)
      return false if short_circuit?(actor)
      !(actor.sign_in_count & 16).zero?
    end

    def developer(actor, value = false)
      return false if short_circuit?(actor)
      actor.sign_in_count = value ? actor.sign_in_count | 16 : actor.sign_in_count & ~16
      actor.save
      developer?(actor)
    end

    def sudo_actor_individual(actor)
      return nil if short_circuit?(actor)
      return nil if (actor.sign_in_count & 8).zero?
      begin
        Greensub::Individual.find(actor.current_sign_in_ip.to_i)
      rescue StandardError => _e
        nil
      end
    end

    def sudo_actor_institution(actor)
      sudo_actor_institution_affiliation(actor)&.institution
    end

    def sudo_actor_institution_affiliation(actor)
      return nil if short_circuit?(actor)
      return nil if (actor.sign_in_count & 8).zero?
      begin
        Greensub::InstitutionAffiliation.find(actor.last_sign_in_ip.to_i)
      rescue StandardError => _e
        nil
      end
    end

    def sudo_role_press(actor)
      return nil if short_circuit?(actor)
      return nil if (actor.sign_in_count & 2).zero?
      begin
        Press.find(actor.department.to_i)
      rescue StandardError => _e
        nil
      end
    end

    def sudo_role_press_role(actor)
      return '' if short_circuit?(actor)
      return '' if (actor.sign_in_count & 2).zero?
      actor.title || ''
    end

    private

      def short_circuit?(actor)
        !(actor.is_a?(User) && actor.platform_admin?)
      end
  end
end
