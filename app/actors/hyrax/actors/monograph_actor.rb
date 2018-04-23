# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  module Actors
    class MonographActor < Hyrax::Actors::BaseActor
      def create(env)
        env = apply_default_group_permissions(env)
        super
      end

      def update(env)
        env = apply_default_group_permissions(env)
        super
      end

      private

        # Add some default read and edit groups for that Press, for that Role
        def apply_default_group_permissions(env)
          press = env.attributes['press'] || env.curation_concern.press
          admin = "#{press}_admin"
          editor = "#{press}_editor"

          (env.attributes["read_groups"] ||= []).push(admin).push(editor)
          (env.attributes["edit_groups"] ||= []).push(admin).push(editor)

          if env.attributes["visibility"] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC ||
             env.curation_concern.public?
            env.attributes["read_groups"].push("public")
          end
          env
        end
    end
  end
end
