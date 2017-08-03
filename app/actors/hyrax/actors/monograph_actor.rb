# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
module Hyrax
  module Actors
    class MonographActor < Hyrax::Actors::BaseActor
      def create(attributes)
        attributes = apply_default_group_permissions(attributes)
        super
      end

      def update(attributes)
        attributes = apply_default_group_permissions(attributes)
        super
      end

      private

        # If a mongraph is not public (normally draft/private) we want to set up
        # some default read and edit groups for that Press, for that Role
        def apply_default_group_permissions(attributes)
          unless attributes["visibility"] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            admin  = "#{attributes['press']}_admin"
            editor = "#{attributes['press']}_editor"
            attributes["read_groups"] = [admin, editor]
            attributes["edit_groups"] = [admin, editor]
          end
          attributes
        end
    end
  end
end
