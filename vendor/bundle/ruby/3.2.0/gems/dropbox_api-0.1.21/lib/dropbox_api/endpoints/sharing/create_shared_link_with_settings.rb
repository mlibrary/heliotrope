# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class CreateSharedLinkWithSettings < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/create_shared_link_with_settings'
    ResultType  = DropboxApi::Metadata::SharedLinkMetadata
    ErrorType   = DropboxApi::Errors::CreateSharedLinkWithSettingsError

    include DropboxApi::OptionsValidator

    # Create a shared link with custom settings. If no settings are given then
    # the default visibility is :public. (The resolved
    # visibility, though, may depend on other aspects such as team and shared
    # folder settings).
    #
    # NOTE: The `settings` parameter will only work for pro, business or
    # enterprise accounts. It will return no permission error otherwise.
    #
    # @param path [String] The path to be shared by the shared link.
    # @param settings [SharedLinkSettings] The requested settings for the newly
    #   created shared link This field is optional.
    # @return [DropboxApi::Metadata::SharedLinkMetadata]
    #
    # @option settings requested_visibility The requested access for this
    #   shared link. This field is optional. Must be one of "public",
    #   "team_only" or "password".
    # @option settings link_password If requested_visibility is
    #   "password" this is needed to specify the password to access the link.
    #   This field is optional.
    # @option settings expires Expiration time of the shared link. By default
    #   the link won't expire. This field is optional.
    add_endpoint :create_shared_link_with_settings do |path, settings = {}|
      validate_options([
        :requested_visibility,
        :link_password,
        :expires
      ], settings)
      settings[:requested_visibility] ||= 'public'
      settings[:link_password] ||= nil
      settings[:expires] ||= nil

      perform_request({
        path: path,
        settings: settings
      })
    end
  end
end
