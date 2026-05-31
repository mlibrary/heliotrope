module IIIFManifest
  module V3
    class ManifestBuilder
      class ThumbnailBuilder
        attr_reader :display_content, :iiif_thumbnail_factory, :image_service_builder_factory
        def initialize(display_content, iiif_thumbnail_factory:, image_service_builder_factory:)
          @display_content = display_content
          @iiif_thumbnail_factory = iiif_thumbnail_factory
          @image_service_builder_factory = image_service_builder_factory
        end

        # @return [Array<Object>]
        def build
          return Array(display_content.thumbnail.map(&:stringify_keys)) unless display_content.thumbnail.nil?
          return nil if display_content.type != "Image" || iiif_endpoint.nil?

          build_thumbnail
          image_service_builder.apply(thumbnail)
          [thumbnail]
        end

        private

        def build_thumbnail
          thumbnail['id'] = File.join(
            display_content.iiif_endpoint.url,
            'full',
            "!#{max_edge},#{max_edge}",
            '0',
            'default.jpg'
          )
          thumbnail['type'] = display_content.type
          thumbnail['height'] = (display_content.height * reduction_ratio).round
          thumbnail['width'] = (display_content.width * reduction_ratio).round
          thumbnail['format'] = display_content.format
        end

        def reduction_ratio
          width = display_content.width
          height = display_content.height
          max_edge = @max_edge.to_f
          return 1 if width <= max_edge && height <= max_edge

          long_edge = [height, width].max
          max_edge / long_edge
        end

        def max_edge
          @max_edge = ::IIIFManifest.config.max_edge_for_thumbnail
        end

        def thumbnail
          @thumbnail ||= iiif_thumbnail_factory.new
        end

        def iiif_endpoint
          display_content.try(:iiif_endpoint)
        end

        def image_service_builder
          image_service_builder_factory.new(iiif_endpoint)
        end
      end
    end
  end
end
