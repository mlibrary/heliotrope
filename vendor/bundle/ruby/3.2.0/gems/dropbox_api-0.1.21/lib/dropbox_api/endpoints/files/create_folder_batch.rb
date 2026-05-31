# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class CreateFolderBatch < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/create_folder_batch'
    ResultType  = DropboxApi::Results::CreateFolderBatchResult

    include DropboxApi::OptionsValidator

    # Create multiple folders at once.
    #
    # This route is asynchronous for large batches, which returns a job ID
    # immediately and runs the create folder batch asynchronously. Otherwise,
    # creates the folders and returns the result synchronously for smaller
    # inputs. You can force asynchronous behaviour by using the `:force_async`
    # flag. Use {Client#create_folder_batch_check} to check the job status.
    #
    # Note: No errors are returned by this endpoint.
    #
    # @param paths [Array] List of paths to be created in the user's Dropbox.
    #   Duplicate path arguments in the batch are considered only once.
    # @option options autorename [Boolean] If there's a conflict, have the
    #   Dropbox server try to autorename the folder to avoid the conflict.
    #   The default for this field is `false`.
    # @option options force_async [Boolean] Whether to force the create to
    #   happen asynchronously. The default for this field is `false`.
    # @return [String, Array] Either the job id or the list of job statuses.
    add_endpoint :create_folder_batch do |paths, options = {}|
      validate_options([
        :autorename,
        :force_async
      ], options)
      options[:autorename] ||= false
      options[:force_async] ||= false

      perform_request(options.merge({
        paths: paths
      }))
    end
  end
end
