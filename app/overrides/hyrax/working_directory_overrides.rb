# frozen_string_literal: true

require 'tempfile'

Hyrax::WorkingDirectory.singleton_class.class_eval do
  prepend(HeliotropeWorkingDirectoryOverrides = Module.new do
    def copy_repository_resource_to_working_directory(file, id)
      Hyrax.logger.debug "Streaming #{file.original_name} (#{file.id}) from the repository to the working directory"
      working_path = full_filename(id, file.original_name)
      FileUtils.mkdir_p(File.dirname(working_path))

      # Avoid file.content, which loads the entire binary into a Ruby string.
      # Publish the working copy only after the download has completed.
      Tempfile.create(['repository-download', '.tmp'], File.dirname(working_path)) do |download|
        download.binmode
        file.stream.each { |chunk| download.write(chunk) }
        download.close
        File.rename(download.path, working_path)
      end

      working_path
    end
  end)
end
