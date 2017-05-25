# frozen_string_literal: true

class CharacterizeJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    filename = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    raise LoadError, "#{file_set.class.characterization_proxy} was not found" unless file_set.characterization_proxy?

    # Override CC
    # On file updates characterization seemingly adds new height/width to an existing original_file
    # array in apparently random places... not in the beginning, not the end (usually!).
    # I don't get it. Just reset them. We need accurate height/width for riiif and leaflet
    file_set.original_file.height = []
    file_set.original_file.width  = []
    # Also in case of a file update, clear out the riiif cached base image if one exisits
    cached_file = Rails.root.join('tmp', 'network_files', Digest::MD5.hexdigest(file_set.original_file.uri.to_s))
    File.delete(cached_file) if File.exist?(cached_file)

    Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filename)
    Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
    file_set.characterization_proxy.save!
    file_set.update_index
    file_set.parent.in_collections.each(&:update_index) if file_set.parent
    CreateDerivativesJob.perform_later(file_set, file_id, filename)
  end
end
