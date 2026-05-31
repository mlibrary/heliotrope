module IIIF::Image
  module Region
    # Represents an absolute specified region
    class Absolute
      # @param [Integer] x
      # @param [Integer] y
      # @param [Integer] width
      # @param [Integer] height
      def initialize(x, y, width, height)
        @offset_x = x
        @offset_y = y
        @width = width
        @height = height
      end

      attr_reader :offset_x, :offset_y, :width, :height

      def dimensions
        Dimension.new(width: width, height: height)
      end

      def to_s
        "#{offset_x},#{offset_y},#{width},#{height}"
      end
    end
  end
end
