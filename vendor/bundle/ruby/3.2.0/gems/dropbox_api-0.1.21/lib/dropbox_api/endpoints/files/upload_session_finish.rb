# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class UploadSessionFinish < DropboxApi::Endpoints::ContentUpload
    Method      = :post
    Path        = '/2/files/upload_session/finish'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::UploadSessionFinishError

    include DropboxApi::OptionsValidator

    # Finish an upload session and save the uploaded data to the given file
    # path.
    #
    # A single request should not upload more than 150 MB.
    #
    # The maximum size of a file one can upload to an upload session is 350 GB.
    #
    # @param cursor [DropboxApi::Metadata::UploadSessionCursor] Contains the
    #   upload session ID and the offset.
    # @param commit [DropboxApi::Metadata::CommitInfo] Contains the path and
    #   other optional modifiers for the commit.
    add_endpoint :upload_session_finish do |cursor, commit, content = nil|
      perform_request({
        cursor: cursor.to_hash,
        commit: commit.to_hash
      }, content)
    end
  end
end
