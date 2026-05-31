# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class ListFolderMembers < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/list_folder_members'
    ResultType  = DropboxApi::Results::SharedFolderMembers
    ErrorType   = DropboxApi::Errors::SharedFolderAccessError

    include DropboxApi::OptionsValidator

    # Returns shared folder membership by its folder ID.
    #
    # Apps must have full Dropbox access to use this endpoint.
    #
    # @example List folder members.
    #   client.list_folder_members "1231273663"
    #
    # @example List folder members, with detail of permission to make owner.
    #   client.list_folder_members "1231273663", [:make_owner]
    #
    # @param folder_id [String] The ID for the shared folder.
    # @param actions [Array]
    #   This is an optional list of actions. The permissions for the actions
    #   requested will be included in the result.
    # @option options limit [Numeric] The maximum number of results that
    #   include members, groups and invitees to return per request. The default
    #   for this field is 1000.
    # @return [SharedFolderMembers] Shared folder user and group membership.
    # @see Metadata::MemberActionList
    add_endpoint :list_folder_members do |folder_id, actions = [], options = {}|
      validate_options([:limit], options)
      options[:limit] ||= 100

      perform_request options.merge({
        shared_folder_id: folder_id,
        actions: DropboxApi::Metadata::MemberActionList.new(actions)
      })
    end
  end
end
