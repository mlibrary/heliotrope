# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class GetThumbnailBatch < DropboxApi::Endpoints::RpcContent
    Method      = :post
    Path        = '/2/files/get_thumbnail_batch'
    ResultType  = DropboxApi::Results::GetThumbnailBatchResult
    ErrorType   = DropboxApi::Errors::ThumbnailBatchError

    include DropboxApi::OptionsValidator

    # Get a thumbnails for a batch of images.
    #
    # @param paths [Array<String>] The paths to the image files you want thumbnails for.
    # @option options format [:jpeg, :png] The format for the thumbnail image,
    #   `:jpeg` (default) or `:png`. For images that are photos, `:jpeg` should be
    #   preferred, while png is better for screenshots and digital arts. The
    #   default is `:jpeg`.
    # @option options size [:w32h32, :w64h64, :w128h128, :w640h480, :w1024h768]
    #   The size for the thumbnail image. The default is `:w64h64`.
    # @option options mode [:strict, :bestfit, :fitone_bestfit]
    #   How to resize and crop the image to achieve the desired size. The default
    #   for this union is strict.
    add_endpoint :get_thumbnail_batch do |paths, options = {}|
      validate_options([:format, :size, :mode], options)
      options[:format] ||= :jpeg
      options[:size] ||= :w64h64
      options[:mode] ||= :strict

      perform_request entries: build_entries_params(paths, options)
    end

    def build_entries_params(paths, options)
      paths.map do |path|
        options.merge({ path: path })
      end
    end

  end
end
