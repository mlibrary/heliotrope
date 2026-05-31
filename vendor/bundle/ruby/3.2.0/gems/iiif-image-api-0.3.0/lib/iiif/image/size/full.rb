module IIIF::Image
  module Size
    # represents requested full size. Full is deprecated in favor of Max in the IIIF spec
    class Full
      def to_s
        "full"
      end
    end
  end
end
