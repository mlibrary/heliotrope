module IIIF::Image
  module Size
    # The width and height of the returned image is scaled to n% of the width and height
    # of the extracted region. The aspect ratio of the returned image is the same as that
    # of the extracted region.
    class Percent
      # @param percentage [Float]
      def initialize(percentage)
        @percentage = percentage
      end

      attr_reader :percentage

      # @return [Float] scale factor between 0 and 1
      def scale
        percentage / 100
      end

      def to_s
        "pct:#{percentage}"
      end
    end
  end
end
