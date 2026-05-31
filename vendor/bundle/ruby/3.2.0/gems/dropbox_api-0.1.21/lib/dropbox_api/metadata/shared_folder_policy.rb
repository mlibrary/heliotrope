# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {SharedFolderPolicy} object:
  #
  # ```json
  # {
  #   "acl_update_policy" => { ".tag" => "owner" },
  #   "shared_link_policy" => { ".tag" => "anyone" }
  # }
  # ```
  class SharedFolderPolicy < Base
    field :acl_update_policy, Symbol
    field :shared_link_policy, Symbol
  end
end
