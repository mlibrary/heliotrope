# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {SpaceUsage} object:
  #
  # ```json
  # {
  #   "used": 167685342,
  #   "allocation": {
  #     ".tag": "individual",
  #     "allocated": 2147483648
  #   }
  # }
  # ```
  class SpaceUsage < Base
    field :used, String
    field :allocation, DropboxApi::Metadata::SpaceAllocation
  end
end
