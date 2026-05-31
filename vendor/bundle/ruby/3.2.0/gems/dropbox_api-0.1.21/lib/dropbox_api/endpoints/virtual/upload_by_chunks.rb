# frozen_string_literal: true
module DropboxApi
  class Client
    # Creates a new file using the *upload session* endpoints. You can use
    # this method to upload files larger than 150 MB.
    #
    # @example
    #   client = DropboxApi::Client.new
    #   File.open "large file.avi" do |file|
    #     client.upload "/large file.avi", file
    #     #=> #<DropboxApi::Metadata::File: @name="large file.avi" ...>
    #   end
    # @example
    #   client = DropboxApi::Client.new
    #   client.upload "/file.txt", "File contents...", :mode => :add
    #   #=> #<DropboxApi::Metadata::File: @name="file (1).txt" ...>
    # @param path [String] Path in the user's Dropbox to save the file.
    # @param content The contents of the file that will be uploaded. This
    #   could be the result of the `IO::read` method.
    # @option options mode [DropboxApi::Metadata::WriteMode] Selects what to
    #   do if the file already exists. The default is `add`.
    # @option options autorename [Boolean] If there's a conflict, as determined
    #   by `mode`, have the Dropbox server try to autorename the file to avoid
    #   conflict. The default for this field is `false`.
    # @option options client_modified [DateTime] The value to store as the
    #   `client_modified` timestamp. Dropbox automatically records the time at
    #   which the file was written to the Dropbox servers. It can also record
    #   an additional timestamp, provided by Dropbox desktop clients, mobile
    #   clients, and API apps of when the file was actually created or
    #   modified.
    # @option options mute [Boolean] Normally, users are made aware of any
    #   file modifications in their Dropbox account via notifications in the
    #   client software. If `true`, this tells the clients that this
    #   modification shouldn't result in a user notification. The default for
    #   this field is `false`.
    # @option options chunk_size [Numeric] The size of each upload chunk. It
    #   defaults to 4 MiB.
    # @see DropboxApi::Metadata::WriteMode
    #
    # @!group virtual
    def upload_by_chunks(path, content, options = {})
      content = StringIO.new(content) if content.is_a?(String)

      uploader = DropboxApi::ChunkedUploader.new(self, path, content, options)
      uploader.start
      uploader.upload
      uploader.finish
    end
  end
end
