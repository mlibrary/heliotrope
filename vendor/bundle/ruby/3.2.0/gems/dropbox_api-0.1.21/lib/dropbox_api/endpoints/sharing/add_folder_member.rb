# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class AddFolderMember < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/add_folder_member'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = DropboxApi::Errors::AddFolderMemberError

    include DropboxApi::OptionsValidator

    # Allows an owner or editor (if the ACL update policy allows) of a shared
    # folder to add another member.
    #
    # For the new member to get access to all the functionality for this folder,
    # you will need to call `mount_folder` on their behalf.
    #
    # Apps must have full Dropbox access to use this endpoint.
    #
    # The `members` parameter can be an `Array` or a single member element.
    # Each element is represented by either a `String` or a
    # {Metadata::AddMember} object. This parameter can be just a string with
    # an email.
    #
    # You can also build a {Metadata::AddMember} object and use it in the
    # `members` parameter, this allows custom  options for each member.
    #
    # @example
    #   client = DropboxApi::Client.new
    #   client.add_folder_member "1363389221", "somebody@test.com"
    # @param folder_id [String] The ID for the shared folder.
    # @param members [Array<AddMember,String>] The intended list of members to
    #   add. Added members will receive invites to join the shared folder.
    # @option options quiet [Boolean] Whether added members should be notified
    #   via email and device notifications of their invite. The default for
    #   this field is False.
    # @option options custom_message [String] Optional message to display to
    #   added members in their invitation. This field is optional.
    # @see DropboxApi::Metadata::AddMember
    add_endpoint :add_folder_member do |folder_id, members, options = {}|
      validate_options([:quiet, :custom_message], options)
      options[:quiet] ||= false
      options[:custom_message] ||= nil

      perform_request options.merge({
        shared_folder_id: folder_id.to_s,
        members: build_members_param(members)
      })
    end

    private

    def build_members_param(members)
      Array(members).map do |member|
        case member
        when String
          DropboxApi::Metadata::AddMember.build_from_string member
        when DropboxApi::Metadata::AddMember
          member
        else
          raise ArgumentError, "Invalid argument type `#{member.class.name}`"
        end
      end.map(&:to_hash)
    end
  end
end
