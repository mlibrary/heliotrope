# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class DeleteBatch < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/delete_batch'
    ResultType  = DropboxApi::Results::DeleteBatchResult

    # Delete multiple files/folders at once.
    #
    # This route is asynchronous, which returns a job ID immediately and runs
    # the delete batch asynchronously. Use {Client#delete_batch_check} to check
    # the job status.
    #
    # @param entries [Array] List of entries, each entry is a Hash with these
    #   fields: `path` (mandatory) & parent_rev (optional).
    # @return [String, Array] Either the job id or the list of job statuses.
    add_endpoint :delete_batch do |entries|
      perform_request({
        entries: entries
      })
    end
  end
end
