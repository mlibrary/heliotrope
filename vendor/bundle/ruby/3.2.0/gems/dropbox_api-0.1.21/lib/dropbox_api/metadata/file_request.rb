# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {FileRequest} object:
  #
  # ```json
  # {
  #     "id": "oaCAVmEyrqYnkZX9955Y",
  #     "url": "https://www.dropbox.com/request/oaCAVmEyrqYnkZX9955Y",
  #     "title": "Homework submission",
  #     "created": "2015-10-05T17:00:00Z",
  #     "is_open": true,
  #     "file_count": 3,
  #     "destination": "/File Requests/Homework",
  #     "deadline": {
  #         "deadline": "2020-10-12T17:00:00Z",
  #         "allow_late_uploads": {
  #             ".tag": "seven_days"
  #         }
  #     }
  # }
  # ```
  class FileRequest < Base
    field :id, String
    field :url, String
    field :title, String
    field :created, Time
    field :is_open, :boolean
    field :file_count, Integer
    field :destination, String
  end
end
