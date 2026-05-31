# frozen_string_literal: true
module DropboxApi::Metadata
  # This class is used as an adapter so we can create an object of the pertinent
  # class when we need to infer the type from the data.
  #
  # For example, calling `Resource.new({".tag" => "file", :name => ...})` will
  # instantiate a `File` object.
  #
  # So this could initalize an object of either `File`, `Folder` or `Deleted`.
  class Resource
    class << self
      def new(data)
        class_for(data['.tag'].to_sym).new(data)
      end

      private

      def class_for(tag)
        case tag
        when :file
          DropboxApi::Metadata::File
        when :folder
          DropboxApi::Metadata::Folder
        when :deleted
          DropboxApi::Metadata::Deleted
        else
          raise ArgumentError, "Unable to infer resource type for `#{tag}`"
        end
      end
    end
  end
end
