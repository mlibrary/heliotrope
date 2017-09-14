# frozen_string_literal: true

require_relative '../../lib/e_pub/e_pub'
require 'zip'

class EPubsService
  def self.factory(epub_id)
    return EPub::EPub.from(epub_id) if EPub::Cache.cached?(epub_id)
    presenter = Hyrax::FileSetPresenter.new(SolrDocument.new(FileSet.find(epub_id).to_solr), nil, nil)
    return EPub::EPub.null_object unless presenter.epub?
    EPub::EPub.from(epub_id)
  rescue StandardError => e
    Rails.logger.info("### INFO epubs service factory epub from #{epub_id} raised #{e} ###")
    EPub::EPub.null_object
  end
  #
  # Public Interface
  #

  def self.open(epub_id) # called from EPubsController#show
    # Return if EPub is cached
    return if Dir.exist?(EPubsService.epub_path(epub_id))

    # Create the EPub directory to short circuit other asynchronous calls
    EPubsService.make_epub_path(epub_id)

    # Extract the entire EPub in the background (EPubsServiceJob calls EPubsService#cache(epub_id))
    EPubsServiceJob.perform_later(epub_id)
  end

  def self.read(epub_id, file_entry) # called from EPubsController#file
    # Cache the EPub if necessary
    EPubsService.open(epub_id)

    # EPub entry file to read
    epub_entry_file = EPubsService.epub_entry_path(epub_id, file_entry)

    # Cache the EPub entry file if necessary
    EPubsService.cache_epub_entry(epub_id, file_entry) unless File.exist?(epub_entry_file)

    # At this point the EPub entry file exist in the cache so reset the time to live for the entire cached EPub
    FileUtils.touch(EPubsService.epub_path(epub_id))

    # Read the EPub entry file
    File.read(epub_entry_file)
  end

  def self.close(epub_id) # called from ? (Admin Dashboard Utility)
    EPubsService.prune_cache_epub(epub_id)
  end

  #
  # Protected Interface
  #

  def self.cache_epub_entry(epub_id, file_entry) # called from EPubsService#read
    # Get the original EPub from Fedora
    epub_file = FileSet.find(epub_id)&.original_file
    raise EPubsServiceError, "EPub #{epub_id} file is nil." if epub_file.nil?

    # Extract just this EPub entry file from the EPub
    begin
      Zip::File.open_buffer(epub_file.content) do |zip_file|
        EPubsService.make_epub_entry_path(epub_id, file_entry)
        # Gaurd against EPub entry file existing to support asynchronous calls
        zip_file.extract(file_entry, EPubsService.epub_entry_path(epub_id, file_entry)) unless File.exist?(EPubsService.epub_entry_path(epub_id, file_entry))
      end
    rescue Errno::ENOENT
      raise EPubsServiceError, "Entry #{file_entry} in EPub #{epub_id} does not exist."
    rescue Zip::Error
      raise EPubsServiceError, "EPub #{epub_id} is corrupt."
    end
    # At this point the EPub entry file has been cached
  end

  def self.cache_epub(epub_id) # called from EPubsServiceJob
    # Get the original EPub from Fedora
    epub_file = FileSet.find(epub_id)&.original_file
    raise EPubsServiceError, "EPub #{epub_id} file is nil." if epub_file.nil?

    # Extract the entire EPub
    begin
      Zip::File.open_buffer(epub_file.content) do |zip_file|
        zip_file.each do |entry|
          EPubsService.make_epub_entry_path(epub_id, entry.name)
          # Extract just this entry file from the epub (Gaurd against file existing to support asynchronous calls)
          entry.extract(EPubsService.epub_entry_path(epub_id, entry.name)) unless File.exist?(EPubsService.epub_entry_path(epub_id, entry.name))
          # At this point the EPub entry file has been cached
        end
      end
    rescue Zip::Error
      raise EPubsServiceError, "EPub #{epub_id} is corrupt."
    end
    # At this point the EPub has been cached
  end

  def self.prune_cache # called from EPubsServiceJob
    return unless Dir.exist?(EPubsService.epubs_path)
    Dir.glob(File.join(EPubsService.epubs_path, "*")).each do |entry|
      FileUtils.rm_rf(entry) if (Time.now - File.mtime(entry)) / 1.day > 1
    end
  end

  def self.prune_cache_epub(epub_id) # called from EPubsService#close
    FileUtils.rm_rf(EPubsService.epub_path(epub_id)) if Dir.exist?(EPubsService.epub_path(epub_id))
  end

  def self.clear_cache # called from specs
    FileUtils.rm_rf(Dir.glob(File.join(EPubsService.epubs_path, "*"))) if Dir.exist?(EPubsService.epubs_path)
  end

  # Helper Methods...

  def self.epubs_path
    Rails.root.join('tmp', 'epubs')
  end

  def self.epub_path(epub_id)
    File.join(EPubsService.epubs_path, epub_id)
  end

  def self.epub_entry_path(epub_id, file_entry)
    File.join(EPubsService.epub_path(epub_id), file_entry)
  end

  def self.make_epubs_path
    FileUtils.mkdir_p(EPubsService.epubs_path) unless Dir.exist?(EPubsService.epubs_path)
  end

  def self.make_epub_path(epub_id)
    EPubsService.make_epubs_path
    FileUtils.mkdir_p(EPubsService.epub_path(epub_id)) unless Dir.exist?(EPubsService.epub_path(epub_id))
  end

  def self.make_epub_entry_path(epub_id, file_entry)
    EPubsService.make_epubs_path
    epub_dir = EPubsService.epub_path(epub_id)
    file_entry.split(File::SEPARATOR).each do |sub_dir|
      FileUtils.mkdir_p(epub_dir) unless Dir.exist?(epub_dir)
      epub_dir = File.join(epub_dir, sub_dir)
    end
  end
end
