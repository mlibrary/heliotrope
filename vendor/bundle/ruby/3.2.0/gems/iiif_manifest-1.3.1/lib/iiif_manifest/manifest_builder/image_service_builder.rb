module IIIFManifest
  class ManifestBuilder
    class ImageServiceBuilder
      attr_reader :iiif_endpoint, :iiif_service_factory
      def initialize(iiif_endpoint, iiif_service_factory:)
        @iiif_endpoint = iiif_endpoint
        @iiif_service_factory = iiif_service_factory
      end

      def apply(resource)
        service['@context'] = iiif_endpoint.context
        service['@id'] = iiif_endpoint.url
        service['profile'] = iiif_endpoint.profile
        resource.service = service
      end

      private

      def service
        @service ||= iiif_service_factory.new
      end
    end
  end
end
