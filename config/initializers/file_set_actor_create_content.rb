# frozen_string_literal: true

Hyrax::Actors::FileSetActor.class_eval do
  # Called from FileSetsController, AttachFilesToWorkJob, ImportURLJob, IngestLocalFileJob
  # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
  # @param [Symbol, #to_sym] relation
  # @return [Boolean] true on success, false otherwise
  def create_content(file, relation = :original_file)
    # If the file set doesn't have a title or label assigned, set a default.
    file_set.label ||= label_for(file)
    file_set.title = [file_set.label] if file_set.title.blank?
    return false unless file_set.save # Need to save to get an id

    # This is the only change for Heliotrope, allowing external resources to be saved with no ingested file
    return true if file.blank?

    build_file_actor(relation).ingest_file(io_decorator(file))
    true
  end
end
