# frozen_string_literal: true

# Attaches uploaded files and their attributes to the work.
class CreateWithImportFilesActor < Hyrax::Actors::AbstractActor
  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if create was successful
  def create(env)
    files_ids = env.attributes.delete(:uploaded_files_ids)
    files_attributes = env.attributes.delete(:uploaded_files_attributes)
    next_actor.create(env) && create_with_import_files(env, files_ids, files_attributes)
  end

  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if update was successful
  def update(env)
    files_ids = env.attributes.delete(:uploaded_files_ids)
    files_attributes = env.attributes.delete(:uploaded_files_attributes)
    next_actor.update(env) && update_with_import_files(env, files_ids, files_attributes)
  end

  private

    def create_with_import_files(env, files_ids, files_attributes)
      with_import_files(env, files_ids, files_attributes)
    end

    def update_with_import_files(env, files_ids, files_attributes)
      # Currently identical to create but left to be explicit
      with_import_files(env, files_ids, files_attributes)
    end

    def with_import_files(env, files_ids, files_attributes)
      return true if files_ids.blank?
      work = env.curation_concern
      work_attributes = env.attributes.to_h.symbolize_keys
      files = Hyrax::UploadedFile.find(files_ids)
      AttachImportFilesToWorkJob.perform_later(work, work_attributes, files, files_attributes)
      true
    end
end
