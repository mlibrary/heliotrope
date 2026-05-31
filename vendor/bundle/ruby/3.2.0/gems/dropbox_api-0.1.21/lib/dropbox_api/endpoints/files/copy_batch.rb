# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class CopyBatch < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/copy_batch_v2'
    ResultType  = DropboxApi::Results::CopyBatchResult

    include DropboxApi::OptionsValidator

    # Copy multiple files or folders to different locations at once in the
    # user's Dropbox.
    #
    # This will either finish synchronously, or return a job ID and do
    # the async copy job in background. Please use {Client#copy_batch_check}
    # to check the job status.
    #
    # Note: No errors are returned by this endpoint.
    #
    # @param entries [Array<Hash>] List of entries to be moved or copied.
    #   Each entry must be a hash with two keys: `:from_path` & `:to_path`.
    # @option options autorename [Boolean] If there's a conflict with any file,
    #   have the Dropbox server try to autorename that file to avoid the
    #   conflict. The default for this field is `false`.
    # @return [String, Array] Either the job id or the list of job statuses.
    add_endpoint :copy_batch do |entries, options = {}|
      validate_options([
        :autorename
      ], options)
      options[:autorename] ||= false

      perform_request(options.merge({
        entries: entries
      }))
    end
  end
end
