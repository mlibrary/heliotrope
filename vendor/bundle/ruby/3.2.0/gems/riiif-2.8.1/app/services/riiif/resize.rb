module Riiif
  # Represents a resize operation
  class Resize
    # @param size [IIIF::Image::Size] the result the user requested
    # @param image_info []
    def initialize(size, image_info)
      @size = size
      @image_info = image_info
    end

    attr_reader :image_info, :size

    # @return [String] a resize directive for imagemagick to use
    def to_imagemagick
      case size
      when IIIF::Image::Size::Percent
        "#{size.percentage}%"
      when IIIF::Image::Size::Width
        size.width
      when IIIF::Image::Size::Height
        "x#{size.height}"
      when IIIF::Image::Size::Absolute
        "#{size.width}x#{size.height}!"
      when IIIF::Image::Size::BestFit
        "#{size.width}x#{size.height}"
      when IIIF::Image::Size::Max, IIIF::Image::Size::Full
        nil
      else
        raise "unknown size #{size.class}"
      end
    end

    # @return [Integer] the height in pixels
    def height
      case size
      when IIIF::Image::Size::Absolute
        size.height
      when IIIF::Image::Size::Percent
        image_info.height * Integer(size.percentage).to_f / 100
      when IIIF::Image::Size::Width
        size.height_for_aspect_ratio(image_info.aspect)
      else
        image_info.height
      end
    end

    # @return [Integer] the width in pixels
    def width
      case size
      when IIIF::Image::Size::Absolute
        size.width
      when IIIF::Image::Size::Percent
        image_info.width * Integer(size.percentage).to_f / 100
      when IIIF::Image::Size::Height
        size.width_for_aspect_ratio(image_info.aspect)
      else
        image_info.width
      end
    end

    # Should we reduce this image with KDU?
    def reduce?
      case size
      when IIIF::Image::Size::Full, IIIF::Image::Size::Max
        false
      when IIIF::Image::Size::Absolute
        aspect_ratio = width.to_f / height
        in_delta?(image_info.aspect, aspect_ratio, 0.001)
      else
        true
      end
    end

    # This is used for a second resize by imagemagick after resizing
    # by kdu.
    # No need to scale most resize operations (only percent)
    # @param [Integer] factor to scale by
    # @return [IIIF::Image::Size] a copy of self if factor is zero.
    def reduce(factor)
      case size
      when IIIF::Image::Size::Percent
        pct = size.percentage * 2**factor
        IIIF::Image::Size::Percent.new(pct)
      else
        size.dup
      end
    end

    # @return [Integer] the reduction factor for this operation
    def reduction_factor(max_factor = 5)
      return nil unless reduce?
      scale = [width.to_f / image_info.width,
               height.to_f / image_info.height].min
      factor = 0
      raise "I don't know how to scale to #{scale}" if scale > 1
      next_pct = 0.5
      while scale <= next_pct && factor < max_factor
        next_pct /= 2.0
        factor += 1
      end
      factor
    end

    private

      def in_delta?(x1, x2, delta)
        (x1 - x2).abs <= delta
      end
  end
end
