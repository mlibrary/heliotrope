module Hydra::Works
  class DetermineMimeType
    # Determines the mime type for a given file
    # @param [IO, File, Rack::Multipart::UploadedFile, #read] file
    # @param [String, NilClass] original_name of the file
    # @return [String]
    def self.call(file, original_name = nil)
      new(file, original_name).determine_mime_type
    end

    attr_reader :file, :original_name

    def initialize(file, original_name)
      @file = file
      @original_name = original_name
    end

    def determine_mime_type
      return file.mime_type if mime_type?
      return file.content_type if content_type?
      mime_type_from_name_or_path || 'application/octet-stream'
    end

    def mime_type_from_name_or_path
      return Hydra::PCDM::GetMimeTypeForFile.call(original_name) if original_name.present?
      return Hydra::PCDM::GetMimeTypeForFile.call(file.path) if file.respond_to?(:path)
    end

    private

      def mime_type?
        file.respond_to?(:mime_type) && file.mime_type.present?
      end

      def content_type?
        file.respond_to?(:content_type) && file.content_type.present?
      end
  end
end
