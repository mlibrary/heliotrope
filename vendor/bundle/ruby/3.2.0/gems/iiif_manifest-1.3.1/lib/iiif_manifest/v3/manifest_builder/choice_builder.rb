module IIIFManifest
  module V3
    class ManifestBuilder
      class ChoiceBuilder
        attr_reader :display_content, :iiif_annotation_factory, :body_builder_factory, :iiif_choice_factory
        def initialize(display_content, iiif_annotation_factory:, body_builder_factory:, iiif_choice_factory:)
          @display_content = display_content
          @iiif_annotation_factory = iiif_annotation_factory
          @body_builder_factory = body_builder_factory
          @iiif_choice_factory = iiif_choice_factory
          build_choice
        end

        def apply(canvas)
          # Assume first item in canvas is an annotation page
          annotation['id'] = "#{canvas.items.first['id']}/annotation/#{annotation.index}"
          annotation['target'] = canvas['id']
          canvas['width'] = choice.items.first['width']
          canvas['height'] = choice.items.first['height']
          canvas['duration'] = choice.items.first['duration']
          annotation.body = choice
          canvas.items.first.items += [annotation]
        end

        private

        def build_choice
          display_content.each do |content|
            content_body = body_builder(content).apply(iiif_annotation_factory.new)
            choice.items += [content_body]
          end
        end

        def body_builder(content)
          body_builder_factory.new(content)
        end

        def annotation
          @annotation ||= iiif_annotation_factory.new
        end

        def choice
          @choice ||= iiif_choice_factory.new
        end
      end
    end
  end
end
