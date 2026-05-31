# frozen_string_literal: true
module DropboxApi::Metadata
  class FolderLinkMetadata < Base
    field :url, String
    field :name, String
    field :link_permissions, DropboxApi::Metadata::LinkPermissions
    field :id, String, :optional
    field :expires, Time, :optional
    field :path_lower, String, :optional
    field :team_member_info, DropboxApi::Metadata::TeamMemberInfo, :optional
    field :content_owner_team_info, DropboxApi::Metadata::Team, :optional
  end
end
