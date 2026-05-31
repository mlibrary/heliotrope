module IIIFManifest
  class ManifestBuilder
    class ImageBuilder
      attr_reader :display_image, :iiif_annotation_factory, :resource_builder_factory
      def initialize(display_image, iiif_annotation_factory:, resource_builder_factory:)
        @display_image = display_image
        @iiif_annotation_factory = iiif_annotation_factory
        @resource_builder_factory = resource_builder_factory
        build_resource
      end

      def apply(canvas)
        annotation['on'] = canvas['@id']
        canvas['width'] = annotation.resource['width']
        canvas['height'] = annotation.resource['height']
        canvas.images += [annotation]
      end

      private

      def build_resource
        resource_builder.apply(annotation)
      end

      def resource_builder
        resource_builder_factory.new(display_image)
      end

      def annotation
        @annotation ||= iiif_annotation_factory.new
      end
    end
  end
end
