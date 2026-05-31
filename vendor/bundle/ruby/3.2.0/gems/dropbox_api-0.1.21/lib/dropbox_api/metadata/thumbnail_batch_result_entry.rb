# frozen_string_literal: true
module DropboxApi::Metadata
  # This class is used as an adapter so we can create an object of the pertinent
  # class when we need to infer the type from the data.
  #
  # This same pattern is used in `DropboxApi::Metadata::Resource`
  #
  # So this could initalize an object of either `ThumbnailBatchResultData`
  # or `ThumbnailError`.
  class ThumbnailBatchResultEntry
    class << self
      def new(data)
        case data['.tag'].to_sym
        when :success
          DropboxApi::Metadata::ThumbnailBatchResultData.new(data)
        when :failure
          DropboxApi::Errors::ThumbnailError.build('Thumbnail generation failed', data['failure'])
        else
          raise NotImplementedError, "Unknown result type: #{data[".tag"]}"
        end
      end
    end
  end
end
