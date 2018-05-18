# frozen_string_literal: true

class UpdateMonographJob < ApplicationJob
  def perform(current_user, monograph_id)
    monograph_manifest = MonographManifest.new(monograph_id)
    implicit = monograph_manifest.implicit
    explicit = monograph_manifest.explicit
    if explicit.persisted?
      unless implicit == explicit
        manifest = File.open(File.join(explicit.path, explicit.filename), "r")
        Import::Importer.new(
          root_dir: explicit.path,
          user_email: current_user.email,
          monograph_id: monograph_id
        ).import(manifest.read)
        manifest.close
      end
    end
    explicit.destroy(current_user)
  end
end
