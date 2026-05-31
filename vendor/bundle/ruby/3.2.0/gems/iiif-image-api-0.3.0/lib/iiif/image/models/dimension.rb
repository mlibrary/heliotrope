module IIIF::Image
  # Represents the size of a rectangle
  class Dimension
    def initialize(height:, width:)
      @height = height
      @width = width
    end

    attr_reader :height, :width

    # @param scale [Float] scale factor between 0 and 1
    # @return [Dimension]
    def scale(scale)
      Dimension.new(height: height * scale, width: width * scale)
    end

    # Return true if both dimensions of other are greater
    def enclosed_by?(other)
      width <= other.width && height <= other.height
    end

    def ==(other)
      width == other.width && height == other.height
    end

    def aspect
      Rational(width, height)
    end
  end
end
