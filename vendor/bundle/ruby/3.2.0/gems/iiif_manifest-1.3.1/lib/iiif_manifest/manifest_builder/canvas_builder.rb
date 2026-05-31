module IIIFManifest
  class ManifestBuilder
    class CanvasBuilder
      attr_reader :record, :parent, :iiif_canvas_factory, :image_builder

      def initialize(record, parent, iiif_canvas_factory:, image_builder:)
        @record = record
        @parent = parent
        @iiif_canvas_factory = iiif_canvas_factory
        @image_builder = image_builder
        apply_record_properties
        attach_image if display_image
      end

      def canvas
        @canvas ||= iiif_canvas_factory.new
      end

      def path
        "#{parent.manifest_url}/canvas/#{record.id}"
      end

      def apply(sequence)
        return sequence if canvas.images.blank?
        sequence.canvases += [canvas]
        sequence
      end

      private

      def display_image
        record.display_image if record.respond_to?(:display_image)
      end

      def apply_record_properties
        canvas['@id'] = path
        canvas.label = record.to_s
      end

      def attach_image
        image_builder.new(display_image).apply(canvas)
      end
    end
  end
end
