# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class ListFileMembers < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/list_file_members'
    ResultType  = DropboxApi::Results::SharedFileMembers
    ErrorType   = DropboxApi::Errors::SharingFileAccessError

    include DropboxApi::OptionsValidator

    # Use to obtain the members who have been invited to a file, both
    # inherited and uninherited members.
    #
    # Apps must have full Dropbox access to use this endpoint.
    #
    # @example List file members.
    #   client.list_file_members "1231273663"
    #
    # @example List file members, with detail of permission to make owner.
    #   client.list_file_members "1231273663", [:make_owner]
    #
    # @example List file members, using the path instead of file ID.
    #   client.list_file_members "/my/file.pdf"
    #
    # @param file_id [String] The ID for the shared file.
    # @param actions [Array]
    #   This is an optional list of actions. The permissions for the actions
    #   requested will be included in the result.
    # @option options include_inherited [Boolean] Whether to include members
    #   who only have access from a parent shared folder. The default for this
    #   field is `true`.
    # @option options limit [Numeric] The maximum number of results that
    #   include members, groups and invitees to return per request. The default
    #   for this field is 100.
    # @return [SharedFileMembers] Shared file user and group membership.
    # @see Metadata::MemberActionList
    add_endpoint :list_file_members do |file_id, actions = [], options = {}|
      validate_options([:limit, :include_inherited], options)
      options[:limit] ||= 100

      perform_request options.merge({
        file: file_id,
        actions: DropboxApi::Metadata::MemberActionList.new(actions)
      })
    end
  end
end
