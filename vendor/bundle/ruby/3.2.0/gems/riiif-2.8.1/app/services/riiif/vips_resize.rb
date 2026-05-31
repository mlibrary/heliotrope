module Riiif
  # Represents a resize operation
  class VipsResize
    def initialize(size, image)
      @size = size
      @image = image
    end

    attr_reader :size, :image

    # @return the parameters that vips will use to resize the image. This can be
    #   1. A [Float] representing the scale factor, passed to Vips::Image#resize
    #   2. An [Array], where the 1st elem is an Integer and the 2nd is a
    #       Hash of options, passed to Vips::Image#thumbnail
    #   3. [NilClass] when image should not be resized at all
    def to_vips
      case size
      when IIIF::Image::Size::Percent
        size.percentage
      when IIIF::Image::Size::Width
        resize_ratio(:width, image)
      when IIIF::Image::Size::Height
        resize_ratio(:height, image)
      when IIIF::Image::Size::Absolute
        [size.width, { height: size.height, size: :force }]
      when IIIF::Image::Size::BestFit
        [size.width, { height: size.height }]
      when IIIF::Image::Size::Max, IIIF::Image::Size::Full
        nil
      else
        raise "unknown size #{size.class}"
      end
    end

    # @param [Symbol] - which side of the image to calculate, either :width or :height
    # @return [Float] - the scale or percentage to resize the image by; passed to Vips::Image#resize
    def resize_ratio(side, image)
      length = image.send(side)
      target_length = size.send(side)
      if target_length < length
        target_length / length.to_f # Size down
      else
        length / target_length.to_f # Size up
      end
    end
  end
end
