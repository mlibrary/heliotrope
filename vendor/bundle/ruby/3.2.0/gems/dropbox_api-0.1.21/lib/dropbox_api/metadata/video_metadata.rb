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
  class VideoMetadata < Base
    field :dimensions, DropboxApi::Metadata::Dimensions, :optional
    field :location, DropboxApi::Metadata::Location, :optional
    field :time_taken, Time, :optional
    field :duration, Integer, :optional
  end
end
