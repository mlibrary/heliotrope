module Hydra::Works
  class DetermineOriginalName
    # Determines the original name for a given file
    # @param [IO, File, Rack::Multipart::UploadedFile] file
    # @return [String]
    def self.call(file)
      return file.original_name if file.respond_to?(:original_name)
      return file.original_filename if file.respond_to?(:original_filename)
      return ::File.basename(file.path) if file.respond_to?(:path)
      ''
    end
  end
end
