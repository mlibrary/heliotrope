# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class ListFolderGetLatestCursor < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/list_folder/get_latest_cursor'
    ResultType  = DropboxApi::Results::ListFolderGetLatestCursorResult
    ErrorType   = DropboxApi::Errors::ListFolderError

    include DropboxApi::OptionsValidator

    # A way to quickly get a cursor for the folder's state. Unlike
    # {DropboxApi::Client#list_folder}, this doesn't return any entries. This
    # endpoint is for app which only needs to know about new files and
    # modifications and doesn't need to know about files that already exist in
    # Dropbox.
    #
    # @option options path [String] The path to the folder you want to read.
    # @option options recursive [Boolean] If `true`, the list folder operation
    #   will be applied recursively to all subfolders and the response will
    #   contain contents of all subfolders. The default for this field is
    #   `false`.
    # @option options include_media_info [Boolean] If `true`, `media_info` is
    #   set for photo and video. The default for this field is `false`.
    # @option options include_deleted [Boolean] If `true`,
    #   {DropboxApi::Metadata::Deleted} will be returned for deleted
    #   file or folder, otherwise {DropboxApi::Errors::LookupError} will be
    #   returned. The default for this field is `false`.
    add_endpoint :list_folder_get_latest_cursor do |options = {}|
      validate_options([
        :path,
        :recursive,
        :include_media_info,
        :include_deleted,
        :include_has_explicit_shared_members
      ], options)
      options[:recursive] ||= false
      options[:include_media_info] ||= false
      options[:include_deleted] ||= false

      perform_request options
    end
  end
end
