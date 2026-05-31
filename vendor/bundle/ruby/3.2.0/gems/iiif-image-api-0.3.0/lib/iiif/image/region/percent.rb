module IIIF::Image
  module Region
    # represents request cooridnates specified as percentage
    class Percent
      # @param x [Float]
      # @param y [Float]
      # @param width [Float]
      # @param height [Float]
      def initialize(x, y, width, height)
        @x_pct = x
        @y_pct = y
        @width_pct = width
        @height_pct = height
      end

      attr_reader :x_pct, :y_pct, :width_pct, :height_pct

      def to_s
        "pct:#{x_pct},#{y_pct},#{width_pct},#{height_pct}"
      end
    end
  end
end
