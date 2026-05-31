# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {Folder} object:
  #
  # ```json
  # {
  #   "name": "arizona_baby",
  #   "path_lower": "/arizona_baby",
  #   "path_display": "/arizona_baby",
  #   "id": "id:7eWkV5hcfzAAAAAAAAAAAQ"
  # }
  # ```
  class Folder < Base
    field :name, String
    field :path_lower, String
    field :path_display, String
    field :id, String
    field :sharing_info, DropboxApi::Metadata::FolderSharingInfo, :optional

    def to_hash
      super.merge('.tag' => 'folder')
    end
  end
end
