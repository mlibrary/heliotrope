module IIIFManifest
  module V3
    class ManifestBuilder
      class ContentBuilder
        attr_reader :display_content, :iiif_annotation_factory, :body_builder_factory
        def initialize(display_content, iiif_annotation_factory:, body_builder_factory:)
          @display_content = display_content
          @iiif_annotation_factory = iiif_annotation_factory
          @body_builder_factory = body_builder_factory
          build_resource
        end

        def apply(canvas)
          # Assume first item in canvas is an annotation page
          annotation['id'] = "#{canvas.items.first['id']}/annotation/#{annotation.index}"
          annotation['target'] = canvas['id']
          canvas['width'] = annotation.body['width'] if annotation.body['width'].present?
          canvas['height'] = annotation.body['height'] if annotation.body['height'].present?
          canvas['duration'] = annotation.body['duration'] if annotation.body['duration'].present?
          canvas.items.first.items += [annotation]
        end

        private

        def build_resource
          body_builder.apply(annotation)
        end

        def body_builder
          body_builder_factory.new(display_content)
        end

        def annotation
          @annotation ||= iiif_annotation_factory.new
        end
      end
    end
  end
end
