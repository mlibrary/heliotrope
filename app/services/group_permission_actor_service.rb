# frozen_string_literal: true

module GroupPermissionActorService
  # Specs for this are in the Work Actors (which call this service)
  # and then use the shared_examples/group_permission_actor.rb spec
  # We need to apply these permissions to the Work on create/update due
  # to the way we use Roles in heliotrope and what hyrax/blacklight/AF expects...
  def self.apply_default_group_permissions(env)
    new_press = env.attributes['press']
    old_press = env.curation_concern.press

    env.attributes["read_groups"] ||= []
    env.attributes["edit_groups"] ||= []

    if new_press != old_press
      admin = "#{new_press}_admin"
      editor = "#{new_press}_editor"
      # We only have press roles for the current Press, HELIO-2945
      env.attributes["read_groups"].map! { |role| role unless role =~ /_admin$|_editor$/ }.compact
      env.attributes["edit_groups"].map! { |role| role unless role =~ /_admin$|_editor$/ }.compact

      env.attributes["read_groups"].push(admin).push(editor)
      env.attributes["edit_groups"].push(admin).push(editor)
    end

    if env.attributes["visibility"] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC ||
       env.curation_concern.public?
      env.attributes["read_groups"].push("public")
    end
    env
  end
end
