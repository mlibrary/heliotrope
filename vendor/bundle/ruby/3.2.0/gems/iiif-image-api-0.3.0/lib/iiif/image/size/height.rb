module IIIF::Image
  module Size
    # The image or region should be scaled so that its height is exactly equal
    # to the provided parameter, and the width will be a calculated value that
    # maintains the aspect ratio of the extracted region
    class Height
      # @param [Integer] height
      def initialize(height)
        @height = height
      end

      attr_reader :height

      # @param ratio [Rational] the aspect ratio
      def width_for_aspect_ratio(ratio)
        (ratio * height).round
      end

      def to_s
        ",#{height}"
      end
    end
  end
end
