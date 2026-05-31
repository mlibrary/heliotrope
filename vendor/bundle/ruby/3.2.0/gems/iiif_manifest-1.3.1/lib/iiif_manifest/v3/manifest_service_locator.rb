module IIIFManifest
  module V3
    class ManifestServiceLocator < IIIFManifest::ManifestServiceLocator
      class << self
        # Builders which receive a work as an argument to .new and return objects
        #   that respond to #apply.
        def manifest_builders
          composite_builder_factory.new(
            record_property_builder,
            structure_builder,
            composite_builder: composite_builder
          )
        end

        def collection_manifest_builders
          composite_builder_factory.new(
            record_property_builder,
            child_manifest_builder_factory,
            composite_builder: composite_builder
          )
        end

        def iiif_collection_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Collection
        end

        def record_property_builder
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::RecordPropertyBuilder,
            iiif_search_service_factory: iiif_search_service_factory,
            iiif_autocomplete_service_factory: iiif_autocomplete_service_factory,
            canvas_builder_factory: deep_canvas_builder_factory,
            thumbnail_builder_factory: thumbnail_builder_factory
            # canvas_builder_factory: canvas_builder_factory
          )
        end

        def structure_builder
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::StructureBuilder,
            canvas_builder_factory: canvas_builder,
            iiif_range_factory: iiif_range_factory
          )
        end

        def canvas_builder_factory
          IIIFManifest::ManifestBuilder::CanvasBuilderFactory.new(
            composite_builder: composite_builder,
            canvas_builder_factory: canvas_builder
          )
        end

        def canvas_builder
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::CanvasBuilder,
            iiif_canvas_factory: iiif_canvas_factory,
            content_builder: content_builder,
            choice_builder: choice_builder,
            iiif_annotation_page_factory: iiif_annotation_page_factory,
            thumbnail_builder_factory: thumbnail_builder_factory
          )
        end

        def content_builder
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::ContentBuilder,
            iiif_annotation_factory: iiif_annotation_factory,
            body_builder_factory: body_builder_factory
          )
        end

        def choice_builder
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::ChoiceBuilder,
            iiif_annotation_factory: iiif_annotation_factory,
            body_builder_factory: body_builder_factory,
            iiif_choice_factory: iiif_choice_factory
          )
        end

        def body_builder_factory
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::BodyBuilder,
            iiif_body_factory: iiif_body_factory,
            image_service_builder_factory: image_service_builder_factory
          )
        end

        def thumbnail_builder_factory
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::ThumbnailBuilder,
            iiif_thumbnail_factory: iiif_thumbnail_factory,
            image_service_builder_factory: image_service_builder_factory
          )
        end

        def image_service_builder_factory
          IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
            ManifestBuilder::ImageServiceBuilder,
            iiif_service_factory: iiif_service_factory
          )
        end

        def sequence_builder
          raise NotImplementedError
        end

        def sammelband_sequence_builder
          raise NotImplementedError
        end

        def sequence_factory
          raise NotImplementedError
        end

        def iiif_service_factory
          IIIFManifest::V3::ManifestBuilder::IIIFService
        end

        def iiif_body_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Body
        end

        def iiif_choice_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Choice
        end

        def iiif_annotation_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Annotation
        end

        def iiif_annotation_page_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::AnnotationPage
        end

        def iiif_manifest_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest
        end

        def iiif_canvas_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Canvas
        end

        def iiif_range_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Range
        end

        def iiif_search_service_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::SearchService
        end

        def iiif_autocomplete_service_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::AutocompleteService
        end

        def iiif_thumbnail_factory
          IIIFManifest::V3::ManifestBuilder::IIIFManifest::Thumbnail
        end
      end
    end
  end
end
