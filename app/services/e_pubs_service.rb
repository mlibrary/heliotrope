# frozen_string_literal: true

require_dependency 'e_pub'
require 'zip'

class EPubsService
  # def self.factory(id)
  #   return EPub::Publication.from(id) if EPub::Cache.cached?(id)
  #   presenter = Hyrax::FileSetPresenter.new(SolrDocument.new(FileSet.find(id).to_solr), nil, nil)
  #   return EPub::Publication.null_object unless presenter.epub?
  #   EPub::Publication.from(id)
  # rescue StandardError => e
  #   Rails.logger.info("### INFO epubs service factory publication from #{id} raised #{e} ###")
  #   EPub::Publication.null_object
  # end
  #
  # Public Interface
  #

  def self.open(id) # called from EPubsController#show
    # Return if EPub is cached
    return if Dir.exist?(EPubsService.epub_path(id))

    @@monitor ||= Monitor.new # rubocop:disable Style/ClassVars
    @@monitor.synchronize do
      unless Dir.exist?(EPubsService.epub_path(id))
        # Create the EPub directory to short circuit other asynchronous calls
        EPubsService.make_epub_path(id)

        # Extract the entire EPub in the foreground (EPubsServiceJob calls EPubsService#cache(id))
        EPubsServiceJob.perform_now(id)
      end
    end
  end

  def self.read(id, file_entry) # called from EPubsController#file
    # Cache the EPub if necessary
    EPubsService.open(id)

    # EPub entry file to read
    epub_entry_file = EPubsService.epub_entry_path(id, file_entry)

    raise EPubsServiceError, "Entry #{file_entry} in EPub #{id} does not exist." unless File.exist?(epub_entry_file)

    # Reset the time to live for the entire cached EPub
    FileUtils.touch(EPubsService.epub_path(id))

    # Read the EPub entry file
    File.read(epub_entry_file)
  end

  def self.close(id) # called from ? (Admin Dashboard Utility)
    EPubsService.prune_cache_epub(id)
  end

  #
  # Protected Interface
  #

  def self.cache_epub(id) # called from EPubsServiceJob
    # Get the original EPub from Fedora
    epub_file = FileSet.find(id)&.original_file
    raise EPubsServiceError, "EPub #{id} file is nil." if epub_file.nil?

    # Extract the entire EPub
    begin
      Zip::File.open_buffer(epub_file.content) do |zip_file|
        zip_file.each do |entry|
          EPubsService.make_epub_entry_path(id, entry.name)
          # Extract just this entry file from the epub (Gaurd against file existing to support asynchronous calls)
          entry.extract(EPubsService.epub_entry_path(id, entry.name)) unless File.exist?(EPubsService.epub_entry_path(id, entry.name))
          # At this point the EPub entry file has been cached
        end
      end
    rescue Zip::Error
      raise EPubsServiceError, "EPub #{id} is corrupt."
    end
    # At this point the EPub has been cached
  end

  def self.prune_cache # called from EPubsServiceJob
    return unless Dir.exist?(EPubsService.epubs_path)
    Dir.glob(File.join(EPubsService.epubs_path, "*")).each do |entry|
      FileUtils.rm_rf(entry) if (Time.now - File.mtime(entry)) / 1.day > 1
    end
  end

  def self.prune_cache_epub(id) # called from EPubsService#close
    FileUtils.rm_rf(EPubsService.epub_path(id)) if Dir.exist?(EPubsService.epub_path(id))
  end

  def self.clear_cache # called from specs
    FileUtils.rm_rf(Dir.glob(File.join(EPubsService.epubs_path, "*"))) if Dir.exist?(EPubsService.epubs_path)
  end

  # Helper Methods...

  def self.epubs_path
    Rails.root.join('tmp', 'epubs')
  end

  def self.epub_path(id)
    File.join(EPubsService.epubs_path, id)
  end

  def self.epub_entry_path(id, file_entry)
    File.join(EPubsService.epub_path(id), file_entry)
  end

  def self.make_epubs_path
    FileUtils.mkdir_p(EPubsService.epubs_path) unless Dir.exist?(EPubsService.epubs_path)
  end

  def self.make_epub_path(id)
    EPubsService.make_epubs_path
    FileUtils.mkdir_p(EPubsService.epub_path(id)) unless Dir.exist?(EPubsService.epub_path(id))
  end

  def self.make_epub_entry_path(id, file_entry)
    EPubsService.make_epubs_path
    epub_dir = EPubsService.epub_path(id)
    file_entry.split(File::SEPARATOR).each do |sub_dir|
      FileUtils.mkdir_p(epub_dir) unless Dir.exist?(epub_dir)
      epub_dir = File.join(epub_dir, sub_dir)
    end
  end
end
