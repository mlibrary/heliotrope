# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class GetThumbnail < DropboxApi::Endpoints::ContentDownload
    Method      = :post
    Path        = '/2/files/get_thumbnail'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::PreviewError

    include DropboxApi::OptionsValidator

    # Get a thumbnail for an image.
    #
    # This method currently supports files with the following file extensions:
    # jpg, jpeg, png, tiff, tif, gif and bmp. Photos that are larger than 20MB
    # in size won't be converted to a thumbnail.
    #
    # @example
    #   # Save thumbnail to a local file
    #   client = DropboxApi::Client.new
    #   file = File.open("thumbnail.png", "w")
    #   client.get_thumbnail "/dropbox_image.png" do |thumbnail_content|
    #     file.write thumbnail_content
    #   end
    #   file.close
    # @example
    #   # Save thumbnail to a local file with .jpg format
    #   client = DropboxApi::Client.new
    #   file = File.open("thumbnail.jpg", "w")
    #   client.get_thumbnail("/dropbox_image.png", :format => :jpeg) do |thumbnail_content|
    #     file.write thumbnail_content
    #   end
    #   file.close
    # @example
    #   # Upload thumbnail to Amazon S3 (assuming you're using their SDK)
    #   s3_object = AWS::S3.new.s3.buckets['my-bucket'].objects['key']
    #   #=> <AWS::S3::S3Object ...>
    #   client = DropboxApi::Client.new
    #   client.get_thumbnail "/dropbox_image.png" do |thumbnail_content|
    #     s3_object.write thumbnail_content
    #   end
    # @param path [String] The path to the image file you want to thumbnail.
    # @option options format [:jpeg, :png] The format for the thumbnail image,
    #   `:jpeg` (default) or `:png`. For images that are photos, `:jpeg` should be
    #   preferred, while png is better for screenshots and digital arts. The
    #   default is `:jpeg`.
    # @option options size [:w32h32, :w64h64, :w128h128, :w640h480, :w1024h768]
    #   The size for the thumbnail image. The default is `:w64h64`.
    add_endpoint :get_thumbnail do |path, options = {}, &block|
      validate_options([:format, :size], options)
      options[:format] ||= :jpeg
      options[:size] ||= :w64h64

      perform_request(options.merge({
        path: path
      }), &block)
    end
  end
end
