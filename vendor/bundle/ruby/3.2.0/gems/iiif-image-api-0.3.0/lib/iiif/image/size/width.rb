module IIIF::Image
  module Size
    # The image or region should be scaled so that its width is exactly equal
    # to the provided parameter, and the height will be a calculated value that
    # maintains the aspect ratio of the extracted region
    class Width
      # @param [Integer] width
      def initialize(width)
        @width = width
      end

      attr_reader :width

      # @param ratio [Rational] the aspect ratio
      def height_for_aspect_ratio(ratio)
        (width / ratio).round
      end

      def to_s
        "#{width},"
      end
    end
  end
end
