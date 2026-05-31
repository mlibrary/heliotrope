module Riiif
  # This is the result of calling the Riiif.image_info service. It stores the height & width
  class ImageInformation < IIIF::Image::Dimension
    extend Deprecation

    def initialize(*args)
      if args.size == 2
        Deprecation.warn(self, 'calling initialize without kwargs is deprecated. Use named parameters.')
        super(width: args.first, height: args.second)
      else
        @width = args.first[:width]
        @height = args.first[:height]
        @format = args.first[:format]
        @channels = args.first[:channels]
      end
    end
    attr_reader :format, :height, :width, :channels

    def to_h
      { width: width, height: height, format: format, channels: channels }
    end

    # Image information is only valid if height and width are present.
    # If an image info service doesn't have the value yet (not characterized perhaps?)
    # then we wouldn't want to cache this value.
    def valid?
      width.present? && height.present?
    end
  end
end
