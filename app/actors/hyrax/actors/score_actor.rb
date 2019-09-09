# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Score`
module Hyrax
  module Actors
    class ScoreActor < Hyrax::Actors::BaseActor
      # While the behavior here is the same as the MonographActor, in practice
      # the only press we'll allow permissions for will be the carillon press, aka the "Score Press".
      # Those permissions/constraints happen at the controller level and not here.
      def create(env)
        env = GroupPermissionActorService.apply_default_group_permissions(env)
        super
      end

      def update(env)
        env = GroupPermissionActorService.apply_default_group_permissions(env)
        super
      end
    end
  end
end
