# frozen_string_literal: true

# Creates and attaches files to the work
class CreateWithImportFilesActor < Hyrax::Actors::AbstractActor
  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if create was successful
  def create(env)
    files = env.attributes.delete(:files)
    files_metadata = env.attributes.delete(:files_metadata)
    next_actor.create(env) && create_with_import_files(env, files, files_metadata)
  end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if update was successful
  def update(env)
    files = env.attributes.delete(:files)
    files_metadata = env.attributes.delete(:files_metadata)
    next_actor.update(env) && update_with_import_files(env, files, files_metadata)
  end

  private

    def create_with_import_files(env, files, files_metadata)
      return true if files.blank?
      with_import_files(env, files, files_metadata)
      representative_image(env.curation_concern)
      true
    end

    def update_with_import_files(env, files, files_metadata)
      # Currently identical to create but left for explicity
      return true if files.blank?
      with_import_files(env, files, files_metadata)
      representative_image(env.curation_concern)
      true
    end

    def with_import_files(env, files, files_metadata)
      monograph = env.curation_concern
      user = env.user
      monograph_attributes = env.attributes.to_h.symbolize_keys
      monograph_permissions = monograph.permissions.map(&:to_hash)
      files.each_with_index do |filename, i|
        file_set = FileSet.new
        actor = Hyrax::Actors::FileSetActor.new(file_set, user)
        actor.create_metadata(visibility_attributes(monograph_attributes))
        actor.update_metadata(files_metadata[i])
        actor.create_content(File.new(filename)) if filename.present?
        actor.attach_to_work(monograph)
        actor.file_set.permissions_attributes = monograph_permissions
        file_set.save!
      end
    end

    # The attributes used for visibility - used to send as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    # Currently redundant with default behavoir but left as placeholder for explicit assignment
    def representative_image(monograph)
      cover_id = monograph.ordered_members.to_a.first.id
      monograph.representative_id = cover_id
      monograph.thumbnail_id = cover_id
      monograph.save!
    end
end
