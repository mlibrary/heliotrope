# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {SharedFolder} object:
  #
  # ```json
  # {
  #   ".tag" => "complete",
  #   "access_type" => {".tag"=>"owner"},
  #   "is_team_folder" => false,
  #   "policy" => {
  #     "acl_update_policy" => { ".tag" => "owner" },
  #     "shared_link_policy" => { ".tag" => "anyone" }
  #   },
  #   "path_lower" => "/folder_a",
  #   "name" => "folder_a",
  #   "shared_folder_id" => "1231266557",
  #   "time_invited" => "2016-06-04T10:00:35Z"
  # }
  # ```
  class SharedFolder < Base
    field :access_type, String
    field :is_team_folder, :boolean
    field :policy, DropboxApi::Metadata::SharedFolderPolicy
    field :path_lower, String
    field :name, String
    field :shared_folder_id, Integer
    field :time_invited, Time
  end
end
