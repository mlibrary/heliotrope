# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class UploadSessionAppendV2 < DropboxApi::Endpoints::ContentUpload
    Method      = :post
    Path        = '/2/files/upload_session/append_v2'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = DropboxApi::Errors::UploadSessionLookupError

    include DropboxApi::OptionsValidator

    # Append more data to an upload session.
    #
    # When the parameter `close` is set, this call will close the session.
    #
    # A single request should not upload more than 150 MB.
    #
    # The maximum size of a file one can upload to an upload session is 350 GB.
    #
    # Calling this method may update the cursor received. In particular, the
    # offset variable will be increased to match the new position. This allows
    # you to make subsequent calls to the endpoint using the same `cursor`, as
    # you can see in the example.
    #
    # @example
    #   # Rely on the offset position updated by `upload_session_append_v2`
    #   client = DropboxApi::Client.new
    #   cursor = client.upload_session_start('abc')      # cursor.offset => 3
    #   client.upload_session_append_v2(cursor, 'def')   # cursor.offset => 6
    #   client.upload_session_append_v2(cursor, 'ghi')   # cursor.offset => 9
    #   client.upload_session_finish(...)
    # @param cursor [DropboxApi::Metadata::UploadSessionCursor] Contains the
    #   upload session ID and the offset. This cursor will have its offset
    #   updated after a successful call.
    # @option options close [Boolean] If `true`, the current session will be
    #   closed, at which point you won't be able to call
    #   {Client#upload_session_append_v2} anymore with the current session.
    #   The default for this field is `false`.
    # @see UploadSessionCursor
    add_endpoint :upload_session_append_v2 do |cursor, content, options = {}|
      validate_options([
        :close
      ], options)

      perform_request(options.merge({
        cursor: cursor.to_hash
      }), content)

      cursor.offset += content.bytesize
    end
  end
end
