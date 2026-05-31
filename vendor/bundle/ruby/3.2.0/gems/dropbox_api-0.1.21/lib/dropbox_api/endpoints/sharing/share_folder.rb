# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class ShareFolder < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/share_folder'
    ResultType  = DropboxApi::Results::ShareFolderLaunch
    ErrorType   = DropboxApi::Errors::ShareFolderError

    include DropboxApi::OptionsValidator

    # Share a folder with collaborators.
    #
    # Most sharing will be completed synchronously. Large folders will be
    # completed asynchronously. To make testing the async case repeatable, set
    # `force_async`.
    #
    # If a ShareFolderLaunch.async_job_id is returned, you'll need to call
    # check_share_job_status until the action completes to get the metadata
    # for the folder.
    #
    # Apps must have full Dropbox access to use this endpoint.
    #
    # @param path [String] The path to the folder to share. If it does not
    #   exist, then a new one is created.
    # @option options member_policy [:anyone, :team] Who can be a member of
    #   this shared folder. Only applicable if the current user is on a team.
    #   The default is `:anyone`.
    # @option options acl_update_policy [:owner, :editors] Who can add and
    #   remove members of this shared folder. The default is `:owner`.
    # @option options shared_link_policy [:anyone, :members] The policy to
    #   apply to shared links created for content inside this shared folder.
    #   The current user must be on a team to set this policy to `:members`.
    #   The default is `anyone`.
    # @option options force_async [Boolean] Whether to force the share to
    #   happen asynchronously. The default for this field is `false`.
    # @return [DropboxApi::Results::ShareFolderLaunch] Shared folder metadata.
    add_endpoint :share_folder do |path, options = {}|
      validate_options([
        :member_policy,
        :acl_update_policy,
        :shared_link_policy,
        :force_async
      ], options)
      options[:member_policy] ||= :anyone
      options[:acl_update_policy] ||= :owner
      options[:shared_link_policy] ||= :anyone
      options[:force_async] ||= false

      begin
        perform_request options.merge({
          path: path
        })
      rescue DropboxApi::Errors::AlreadySharedError => error
        error.shared_folder
      end
    end
  end
end
