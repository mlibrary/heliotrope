# frozen_string_literal: true
module DropboxApi::Metadata
  # This class is used as an adapter so we can create an object of the pertinent
  # class when we need to infer the type from the data.
  #
  # This same pattern is used in `DropboxApi::Metadata::Resource`
  class SharedLinkMetadata
    class << self
      def new(data)
        class_for(data['.tag'].to_sym).new(data)
      end

      private

      def class_for(tag)
        case tag
        when :file
          DropboxApi::Metadata::FileLinkMetadata
        when :folder
          DropboxApi::Metadata::FolderLinkMetadata
        else
          raise ArgumentError, "Unable to infer resource type for `#{tag}`"
        end
      end
    end
  end
end
