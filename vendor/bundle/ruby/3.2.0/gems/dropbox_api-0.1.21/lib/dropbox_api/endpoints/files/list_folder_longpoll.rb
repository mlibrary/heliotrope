# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class ListFolderLongpoll < DropboxApi::Endpoints::RpcNotify
    Method      = :post
    Path        = '/2/files/list_folder/longpoll'
    ResultType  = DropboxApi::Results::ListFolderLongpollResult
    ErrorType   = DropboxApi::Errors::ListFolderLongpollError

    include DropboxApi::OptionsValidator

    # A longpoll endpoint to wait for changes on an account. In conjunction
    # with list_folder, this call gives you a low-latency way to monitor an
    # account for file changes. The connection will block until there are
    # changes available or a timeout occurs. This endpoint is useful mostly
    # for client-side apps. If you're looking for server-side notifications,
    # check out our webhooks documentation.
    #
    # @param cursor [String] A cursor as returned by list_folder or
    #   list_folder_continue.
    # @option options timeout [Numeric] A timeout in seconds. The request will
    #   block for at most this length of time, plus up to 90 seconds of random
    #   jitter added to avoid the thundering herd problem. Care should be taken
    #   when using this parameter, as some network infrastructure does not
    #   support long timeouts. The default for this field is 30.
    add_endpoint :list_folder_longpoll do |cursor, options = {}|
      validate_options([
        :timeout
      ], options)
      options[:timeout] ||= 30

      perform_request options.merge({
        cursor: cursor
      })
    end
  end
end
