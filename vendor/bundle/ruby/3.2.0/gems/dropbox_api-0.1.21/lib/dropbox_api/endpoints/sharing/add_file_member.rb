# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class AddFileMember < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/add_file_member'
    ResultType  = DropboxApi::Results::AddFileMemberResultList
    ErrorType   = DropboxApi::Errors::AddFileMemberError

    include DropboxApi::OptionsValidator

    # Adds specified members to a file.
    #
    # The `members` parameter can be an `Array` or a single member element. Each
    # element is represented by either a `String` or a {Metadata::Member}
    # object. You can identify a member using his email or a Dropbox ID.
    #
    # @param file [String] File to which to add members. It can be a path or
    #   an ID such as `id:3kmLmQFnf1AAAAAAAAAAAw`.
    # @param members Members to add. Note
    #   that even if an email address is given, this may result in a user
    #   being directy added to the membership if that email is the user's
    #   main account email.
    # @option options quiet [Boolean] Whether added members should be notified
    #   via email and device notifications of their invite. The default for
    #   this field is `false`.
    # @option options custom_message [String] Message to send to added members
    #   in their invitation. This field is optional.
    # @option options access_level [AccessLevel] AccessLevel union object,
    #   describing what access level we want to give new members. The default
    #   for this is `:viewer`.
    # @option options add_message_as_comment [String] Optional message to
    #   display to added members in their invitation. This field is optional.
    # @see DropboxApi::Metadata::Member
    add_endpoint :add_file_member do |file, members, options = {}|
      validate_options([:quiet, :custom_message, :access_level, :add_message_as_comment], options)
      options[:quiet] ||= false
      options[:custom_message] ||= nil
      options[:access_level] ||= :viewer
      options[:add_message_as_comment] ||= false

      perform_request options.merge({
        file: file,
        members: build_members_param(members)
      })
    end

    private

    def build_members_param(members)
      Array(members).map do |member|
        case member
        when String
          DropboxApi::Metadata::Member.new member
        when DropboxApi::Metadata::Member
          member
        else
          raise ArgumentError, "Invalid argument type `#{member.class.name}`"
        end
      end.map(&:to_hash)
    end
  end
end
