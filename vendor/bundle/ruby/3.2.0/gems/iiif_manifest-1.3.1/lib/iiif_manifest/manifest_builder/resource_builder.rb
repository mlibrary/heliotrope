module IIIFManifest
  class ManifestBuilder
    class ResourceBuilder
      attr_reader :display_image, :iiif_resource_factory, :image_service_builder_factory
      def initialize(display_image, iiif_resource_factory:, image_service_builder_factory:)
        @display_image = display_image
        @iiif_resource_factory = iiif_resource_factory
        @image_service_builder_factory = image_service_builder_factory
      end

      def apply(annotation)
        resource['@id'] = display_image.url
        resource['@type'] = 'dctypes:Image'
        resource['height'] = display_image.height
        resource['width'] = display_image.width
        resource['format'] = display_image.format
        image_service_builder.apply(resource) if iiif_endpoint
        annotation.resource = resource
      end

      private

      def resource
        @resource ||= iiif_resource_factory.new
      end

      def iiif_endpoint
        display_image.try(:iiif_endpoint)
      end

      def image_service_builder
        image_service_builder_factory.new(iiif_endpoint)
      end
    end
  end
end
