# Use ruby-vips to execute image transformations (via ffi gem) instead of
# using the vips CLI. Since vips CLI commands can't be chained without creating
# temp files after each operation, using the CLI would decrease performance.
# See 'Chaining operations': https://www.libvips.org/API/current/using-cli.html
require 'ruby-vips' if Riiif::Engine.config.use_vips

module Riiif
  class VipsTransformer < AbstractTransformer
    include ActiveSupport::Benchmarkable
    delegate :logger, to: :Rails

    # @param path [String] The path of the source image file
    # @param image_info [ImageInformation] information about the source
    # @param [IIIF::Image::Transformation] transformation
    def initialize(path, image_info, transformation, compression: 85, subsample: true, strip_metadata: true)
      super(path, image_info, transformation)
      @image = ::Vips::Image.new_from_file(path.to_s)
      @compression = compression
      @subsample = subsample
      @strip_metadata = strip_metadata
    end

    attr_reader :image, :path, :compression, :subsample, :strip_metadata

    # @return [String] all the image data
    def transform
      benchmark("Riiif transformed image using vips") do
        transform_image.write_to_buffer(".#{format}#{format_options}")
      end
    end

    private

    # Chain every method in the array together and apply it to the image
    # @return [Vips::Image] - the image after all transformations
    def transform_image
      result = [crop, resize, rotate, colourspace].reduce(image) do |image, array|
        method, options = array
        # Options are blank when transformation is not required (e.g. when requesting full size)
        next image if options.blank?

        case method
        when :resize
          image.send(method, VipsResize.new(transformation.size, image).to_vips)
        when :thumbnail_image
          # .thumbnail_image needs a positional argument (width) and keyword args (options)
          # https://www.rubydoc.info/gems/ruby-vips/Vips/Image#thumbnail_image-instance_method
          image.send(method, options.first, **options.last)
        when :crop
          # .crop needs positional arguments
          image.send(method, *options)
        else # :rotate or :colourspace
          image.send(method, options)
        end
      end
      # If result should be bitonal, set a value threshold
      # https://github.com/libvips/libvips/issues/1840
      transformation.quality == 'bitonal' ? (result > 200) : result
    end

    def format
      # In cases where the input file has an alpha_channel but the transformation
      # format is 'jpg', change to 'png' as jpeg does not support alpha channels
      image.has_alpha? && transformation.format == 'jpg' ? 'png' : transformation.format
    end

    def format_options
      format_string = [compression,
                       ("optimize-coding" if format == 'jpg'),
                       ("strip" if strip_metadata),
                       ("no-subsample" unless subsample)].select(&:present?).join(',')

      "[Q=#{format_string}]"
    end

    def resize
      case transformation.size
      when IIIF::Image::Size::Percent, IIIF::Image::Size::Width, IIIF::Image::Size::Height
        [:resize, transformation.size]
      else # IIIF::Image::Size::Absolute, IIIF::Image::Size::BestFit
        [:thumbnail_image, VipsResize.new(transformation.size, image).to_vips]
      end
    end

    def crop
      [:crop, Crop.new(transformation.region, image_info).to_vips]
    end

    def rotate
      angle = transformation.rotation.zero? ? nil : transformation.rotation
      [:rotate, angle]
    end

    def colourspace
      case transformation.quality
      when 'gray', 'bitonal'
        [:colourspace, :b_w]
      else
        [:colourspace, nil]
      end
    end
  end
end
