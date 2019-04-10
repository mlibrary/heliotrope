# frozen_string_literal: true

class CharacterizeJob < ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    filename = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    raise LoadError, "#{file_set.class.characterization_proxy} was not found" unless file_set.characterization_proxy?

    # Override CC/Hyrax, see https://github.com/samvera/hyrax/issues/1152
    # store this so we can tell if the original_file is changing
    previous_checksum = file_set.original_file.original_checksum.first

    # On file updates characterization adds new height/width/size/checksum values to an unorderable ActiveTriples::Relation on original_file
    # We need accurate height/width for riiif and leaflet, and want as clean a "recharacterization" as possible
    file_set.original_file.height = []
    file_set.original_file.width  = []
    file_set.original_file.original_checksum = []
    file_set.original_file.file_size = []
    file_set.original_file.format_label = []
    # if the current FileSet title is the same as the label, it's a file name (as opposed to user-entered)...
    # and we'll set it to the new file's name
    reset_title = file_set.title.first == file_set.label

    # Also in case of a file update, clear out the riiif cached base image if one exists
    cached_file = Rails.root.join('tmp', 'network_files', Digest::MD5.hexdigest(file_set.original_file.uri.to_s))
    File.delete(cached_file) if File.exist?(cached_file)

    Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filename)

    Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
    file_set.characterization_proxy.save!

    # Override CC/Hyrax, see https://github.com/samvera/hyrax/issues/1152
    # Probably not ideal to make edits to the FileSet itself here, rather than just the characterization_proxy...
    # (a.k.a. original_file for us). But these things make sense to do, and the job is asynchronous.
    if file_set.original_checksum.first != previous_checksum
      # actual file has changed, change the mod timestamp on the FileSet object (for APTrust bagging etc)
      file_set.date_modified = Hyrax::TimeService.time_in_utc
    end
    file_set.title = [file_set.characterization_proxy.original_name] if reset_title
    file_set.label = file_set.characterization_proxy.original_name
    # save will do this now that we're updating the FileSet
    # file_set.update_index
    file_set.save!

    file_set.parent&.in_collections&.each(&:update_index)

    # Heliotrope addition: allow "reversioned" FileSets to be Unpacked if needed
    kind = FeaturedRepresentative.where(file_set_id: file_set.id)&.first&.kind
    # HACK: for HELIO-1830
    if kind.blank? && file_set.parent&.press == 'heb'
      kind = maybe_set_featured_representative(file_set)
    end
    if kind.present? && ['epub', 'webgl'].include?(kind)
      UnpackJob.perform_later(file_set.id, kind)
    end

    CreateDerivativesJob.perform_later(file_set, file_id, filename)
  end

  def maybe_set_featured_representative(file_set)
    kind = case file_set.original_file.file_name.first
           when /\.epub$/
             "epub"
           when "related.html"
             "related"
           when "reviews.html"
             "reviews"
           end

    if kind.present?
      FeaturedRepresentative.create!(monograph_id: file_set.parent.id,
                                     file_set_id: file_set.id,
                                     kind: kind)
    end
    kind
  end
end
