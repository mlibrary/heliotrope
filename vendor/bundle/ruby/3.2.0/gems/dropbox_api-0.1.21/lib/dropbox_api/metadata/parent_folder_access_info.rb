# frozen_string_literal: true
module DropboxApi::Metadata
  class ParentFolderAccessInfo < Base
    field :folder_name, String
    field :shared_folder_id, String
    field :permissions, DropboxApi::Metadata::MemberPermissionList
  end
end
