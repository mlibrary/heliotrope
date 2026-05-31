module IIIFManifest
  module V3
    class DisplayContent
      attr_reader :url, :width, :height, :duration, :iiif_endpoint, :format, :type,
                  :label, :auth_service, :thumbnail
      def initialize(url, type:, **kwargs)
        @url = url
        @type = type
        @width = kwargs[:width]
        @height = kwargs[:height]
        @duration = kwargs[:duration]
        @label = kwargs[:label]
        @format = kwargs[:format]
        @iiif_endpoint = kwargs[:iiif_endpoint]
        @auth_service = kwargs[:auth_service]
        @thumbnail = kwargs[:thumbnail]
      end
    end
  end
end
