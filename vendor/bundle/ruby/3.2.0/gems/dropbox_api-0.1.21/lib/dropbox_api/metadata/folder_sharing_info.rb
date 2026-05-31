# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {FolderSharingInfo} object:
  #
  # ```json
  # {
  #   "read_only": false,
  #   "parent_shared_folder_id": "84528192421"
  # }
  # ```
  class FolderSharingInfo < Base
    field :read_only, :boolean
    field :parent_shared_folder_id, String, :optional
    field :shared_folder_id, String, :optional
  end
end
