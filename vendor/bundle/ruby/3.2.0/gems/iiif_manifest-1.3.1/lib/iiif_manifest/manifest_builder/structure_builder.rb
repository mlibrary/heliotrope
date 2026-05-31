module IIIFManifest
  class ManifestBuilder
    class StructureBuilder
      attr_reader :record, :canvas_builder_factory, :iiif_range_factory
      def initialize(record, canvas_builder_factory:, iiif_range_factory:)
        @record = record
        @canvas_builder_factory = canvas_builder_factory
        @iiif_range_factory = iiif_range_factory
      end

      def apply(manifest)
        top_ranges.each do |top_range|
          manifest['structures'] ||= []
          manifest['structures'] = range_builder(top_range).apply(manifest['structures'])
        end
        manifest
      end

      def range_builder(top_range)
        RangeBuilder.new(
          top_range,
          record, true,
          canvas_builder_factory: canvas_builder_factory,
          iiif_range_factory: iiif_range_factory
        )
      end

      def top_ranges
        record.try(:ranges) || []
      end
    end
    class RangeBuilder
      attr_reader :record, :parent, :canvas_builder_factory, :iiif_range_factory
      delegate :file_set_presenters, to: :record
      def initialize(record, parent, top = false, canvas_builder_factory:, iiif_range_factory:)
        @record = record
        @parent = parent
        @top = top
        @canvas_builder_factory = canvas_builder_factory
        @iiif_range_factory = iiif_range_factory
        build_range
      end

      def path
        "#{parent.manifest_url}/range/r#{index}"
      end

      def index
        @index ||= SecureRandom.uuid
      end

      def apply(manifest)
        manifest << range
        sub_ranges.map do |sub_range|
          manifest = sub_range.apply(manifest)
        end
        manifest
      end

      def build_range
        range['@id'] = path
        range['label'] = record.label
        range['viewingHint'] = 'top' if top?
        range['ranges'] = sub_ranges.map(&:path)
        range['canvases'] = canvas_builders.map(&:path)
      end

      def sub_ranges
        @sub_ranges ||= record.ranges.map do |sub_range|
          RangeBuilder.new(
            sub_range,
            parent,
            canvas_builder_factory: canvas_builder_factory,
            iiif_range_factory: iiif_range_factory
          )
        end
      end

      def canvas_builders
        @canvas_builders ||= file_set_presenters.map do |file_set_presenter|
          canvas_builder_factory.new(file_set_presenter, parent)
        end
      end

      def range
        @range ||= iiif_range_factory.new
      end

      def top?
        @top
      end
    end
  end
end
