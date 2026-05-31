module Hydra::PCDM
  module GetMimeTypeForFile
    def self.call(path)
      raise ArgumentError, 'supplied argument should be a path to a file' unless path.is_a?(String)
      mime_types = ::MIME::Types.of(::File.basename(path))
      mime_types.empty? ? 'application/octet-stream' : mime_types.first.content_type
    end
  end
end
