module IIIF::Image
  module Size
    # The image content is scaled for the best fit such that the resulting width and
    # height are less than or equal to the requested width and height.
    class BestFit
      # @param [Integer] width
      # @param [Integer] height
      def initialize(width, height)
        @width = width
        @height = height
      end

      attr_reader :height, :width

      def to_s
        "!#{width},#{height}"
      end
    end
  end
end
