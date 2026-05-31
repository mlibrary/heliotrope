module IIIF::Image
  module Region
    # Represents the image or region requested at its full size.
    # This is a nil crop operation.
    class Full
      def to_s
        'full'
      end
    end
  end
end
