# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  module Actors
    class MonographActor < Hyrax::Actors::BaseActor
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
