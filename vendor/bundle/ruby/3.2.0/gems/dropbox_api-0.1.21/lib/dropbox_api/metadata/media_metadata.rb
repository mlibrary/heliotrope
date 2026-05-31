# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {MediaInfo} object:
  # 
  # ```json
  # {
  #   ".tag": "video",
  #   "dimensions": {
  #     "height": 1500,
  #     "width": 1500
  #   },
  #   "location": {
  #     "latitude": 10.123456,
  #     "longitude": 5.123456
  #   }
  #   "time_taken": "2016-09-04T17:00:27Z",
  #   "duration": 6000
  # }
  # ```
  class MediaMetadata < Base
    class << self
      def new(data)
        tag = data['.tag']
        class_for(tag.to_sym).new(data)
      end

      private

      def class_for(tag)
        case tag
        when :photo
          DropboxApi::Metadata::PhotoMetadata
        when :video
          DropboxApi::Metadata::VideoMetadata
        else
          raise ArgumentError, "Unable to build individual result with `#{tag}`"
        end
      end
    end
  end
end
