module IIIFManifest
  module V3
    class ManifestBuilder
      class ImageServiceBuilder
        attr_reader :iiif_endpoint, :iiif_service_factory
        def initialize(iiif_endpoint, iiif_service_factory:)
          @iiif_endpoint = iiif_endpoint
          @iiif_service_factory = iiif_service_factory
        end

        def apply(resource)
          service['@id'] = iiif_endpoint.url
          service['profile'] = iiif_endpoint.profile
          service['@type'] = determine_type(iiif_endpoint.context)
          resource.service = [service]
        end

        private

        def determine_type(context)
          case context
          when 'http://iiif.io/api/image/1/context.json'
            'ImageService1'
          when 'http://iiif.io/api/image/2/context.json'
            'ImageService2'
          end
        end

        def service
          @service ||= iiif_service_factory.new
        end
      end
    end
  end
end
