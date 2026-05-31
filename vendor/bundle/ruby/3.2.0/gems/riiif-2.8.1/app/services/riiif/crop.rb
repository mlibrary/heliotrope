module Riiif
  # Represents a cropping operation
  class Crop
    # @param transformation [IIIF::Image::Region] the result the user requested
    # @param image_info []
    def initialize(region, image_info)
      @region = region
      @image_info = image_info
    end

    attr_reader :image_info, :region

    # @return [String] a region for imagemagick to decode
    #                  (appropriate for passing to the -crop parameter)
    def to_imagemagick
      case region
      when IIIF::Image::Region::Full
        nil
      when IIIF::Image::Region::Absolute
        "#{region.width}x#{region.height}+#{region.offset_x}+#{region.offset_y}"
      when IIIF::Image::Region::Square
        imagemagick_square
      when IIIF::Image::Region::Percent
        imagemagick_percent
      else
        raise "Unknown region #{region.class}"
      end
    end

    # @return [String] a region for kakadu to decode
    #                  (appropriate for passing to the -region parameter)
    def to_kakadu
      case region
      when IIIF::Image::Region::Full
        nil
      when IIIF::Image::Region::Absolute
        "\{#{decimal_offset_y(region.offset_y)},#{decimal_offset_x(region.offset_x)}\}," \
        "\{#{decimal_height(region.height)},#{decimal_width(region.width)}\}"
      when IIIF::Image::Region::Square
        kakadu_square
      when IIIF::Image::Region::Percent
        kakadu_percent
      else
        raise "Unknown region #{region.class}"
      end
    end

    def to_vips
      case region
      when IIIF::Image::Region::Full
        nil
      when IIIF::Image::Region::Absolute
        [region.offset_x, region.offset_y, region.width, region.height]
      when IIIF::Image::Region::Square
        vips_square
      when IIIF::Image::Region::Percent
        vips_percent
      end
    end

    private

      def vips_percent
        # Calculate x values
        offset_x, width = [region.x_pct, region.width_pct].map do |percent|
          (image_info.width * percentage_to_fraction(percent)).round
        end

        # Calculate y values
        offset_y, height = [region.y_pct, region.height_pct].map do |percent|
          (image_info.height * percentage_to_fraction(percent)).round
        end

        [offset_x, offset_y, width, height]
      end

      def imagemagick_percent
        offset_x = (image_info.width * percentage_to_fraction(region.x_pct)).round
        offset_y = (image_info.height * percentage_to_fraction(region.y_pct)).round
        "#{region.width_pct}%x#{region.height_pct}+#{offset_x}+#{offset_y}"
      end

      def kakadu_percent
        offset_x = (image_info.width * percentage_to_fraction(region.x_pct)).round
        offset_y = (image_info.height * percentage_to_fraction(region.y_pct)).round
        "\{#{decimal_offset_y(offset_y)},#{decimal_offset_x(offset_x)}\}," \
        "\{#{percentage_to_fraction(region.height_pct)},#{percentage_to_fraction(region.width_pct)}\}"
      end

      def vips_square
        min, max = [image_info.width, image_info.height].minmax
        offset = (max - min) / 2

        if image_info.height >= image_info.width
          # Portrait: left, offset, width, height
          [0, offset, min, min]
        else
          # Landscape: left, offset, width, height
          [offset, 0, min, min]
        end
      end

      def kakadu_square
        min, max = [image_info.width, image_info.height].minmax
        offset = (max - min) / 2
        if image_info.height >= image_info.width
          # Portrait
          "\{#{decimal_height(offset)},0\}," \
          "\{#{decimal_height(image_info.height)},#{decimal_width(image_info.height)}\}"
        else
          # Landscape
          "\{0,#{decimal_width(offset)}\}," \
          "\{#{decimal_height(image_info.width)},#{decimal_width(image_info.width)}\}"
        end
      end

      def imagemagick_square
        min, max = [image_info.width, image_info.height].minmax
        offset = (max - min) / 2
        if image_info.height >= image_info.width
          "#{min}x#{min}+0+#{offset}"
        else
          "#{min}x#{min}+#{offset}+0"
        end
      end

      # @return [Integer] the height in pixels
      def height
        image_info.height
      end

      # @return [Integer] the width in pixels
      def width
        image_info.width
      end

      # @return [Float] the fractional height with respect to the original size
      def decimal_height(n = height)
        n.to_f / image_info.height
      end

      # @return [Float] the fractional width with respect to the original size
      def decimal_width(n = width)
        n.to_f / image_info.width
      end

      def decimal_offset_x(offset_x)
        offset_x.to_f / image_info.width
      end

      def decimal_offset_y(offset_y)
        offset_y.to_f / image_info.height
      end

      def maintain_aspect_ratio?
        (height / width) == (image_info.height / image_info.width)
      end

      def percentage_to_fraction(n)
        n / 100.0
      end
  end
end
