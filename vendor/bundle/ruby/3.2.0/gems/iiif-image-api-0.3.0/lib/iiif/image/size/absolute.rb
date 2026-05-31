module IIIF::Image
  module Size
    # The width and height of the returned image are exactly w and h.
    # The aspect ratio of the returned image may be different than the extracted
    # region, resulting in a distorted image.
    class Absolute
      # @param [Integer] width
      # @param [Integer] height
      def initialize(width, height)
        @width = width
        @height = height
      end

      attr_reader :height, :width

      def to_s
        "#{width},#{height}"
      end
    end
  end
end
