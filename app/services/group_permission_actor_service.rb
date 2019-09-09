# frozen_string_literal: true

module GroupPermissionActorService
  # Specs for this are in the Work Actors (which call this service)
  # and then use the shared_examples/group_permission_actor.rb spec
  # We need to apply these permissions to the Work on create/update due
  # to the way we use Roles in heliotrope and what hyrax/blacklight/AF expects...
  def self.apply_default_group_permissions(env)
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
