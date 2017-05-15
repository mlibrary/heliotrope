# frozen_string_literal: true

Hyrax::Actors::FileSetActor.class_eval do
  # Called from AttachFilesActor, FileSetsController, AttachFilesToWorkJob, ImportURLJob, IngestLocalFileJob
  # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file uploaded by the user.
  # @param [String] relation ('original_file')
  # @param [Boolean] asynchronous (true) set to false if you don't want to launch a new background job.
  def create_content(file, relation = 'original_file', asynchronous = true)
    # If the file set doesn't have a title or label assigned, set a default.
    file_set.label ||= file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file)
    file_set.title = [file_set.label] if file_set.title.blank?
    return false unless file_set.save # Need to save the file_set in order to get an id

    # This is the only change for Heliotrope, allowing external resources to be saved with no ingested file
    return true if file.blank?

    file_actor_class.new(file_set, relation, user).ingest_file(file, asynchronous)
    true
  end
end
