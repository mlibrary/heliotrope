module IIIFManifest
  class ManifestBuilder
    class RecordPropertyBuilder
      attr_reader :record, :iiif_search_service_factory, :iiif_autocomplete_service_factory
      def initialize(record, iiif_search_service_factory:, iiif_autocomplete_service_factory:)
        @record = record
        @iiif_search_service_factory = iiif_search_service_factory
        @iiif_autocomplete_service_factory = iiif_autocomplete_service_factory
      end

      def apply(manifest)
        manifest['@id'] = record.manifest_url.to_s
        label = Array(::IIIFManifest.config.manifest_value_for(record, property: :label)).first
        manifest.label = label
        description = Array(::IIIFManifest.config.manifest_value_for(record, property: :description)).first
        manifest.description = description
        manifest.viewing_hint = viewing_hint if viewing_hint.present?
        manifest.viewing_direction = viewing_direction if viewing_direction.present?
        manifest.metadata = record.manifest_metadata if valid_metadata?
        manifest.service = services if search_service.present?
        manifest
      end
      # rubocop:enable Metrics/AbcSize

      private

      def viewing_hint
        (record.respond_to?(:viewing_hint) && record.send(:viewing_hint))
      end

      def viewing_direction
        (record.respond_to?(:viewing_direction) && record.send(:viewing_direction))
      end

      def autocomplete_service
        (record.respond_to?(:autocomplete_service) && record.send(:autocomplete_service))
      end

      def search_service
        (record.respond_to?(:search_service) && record.send(:search_service))
      end

      def iiif_search_service
        @iiif_search_service ||= iiif_search_service_factory.new
      end

      def iiif_autocomplete_service
        @iiif_autocomplete_service ||= iiif_autocomplete_service_factory.new
      end

        # Build services. Currently supported:
        #   search_service, with (optional) embedded autocomplete service
        #
        # @return [Array] array of services
      def services
        iiif_search_service.search_service = search_service
        iiif_autocomplete_service.autocomplete_service = autocomplete_service
        iiif_search_service.service = iiif_autocomplete_service if autocomplete_service.present?
        [iiif_search_service]
      end

        # Validate manifest_metadata against the IIIF spec format for metadata
        #
        # @return [Boolean]
      def valid_metadata?
        return false unless record.respond_to?(:manifest_metadata)
        metadata = record.manifest_metadata
        valid_metadata_structure?(metadata) && valid_metadata_content?(metadata)
      end

        # Manifest metadata must be an array containing hashes
        #
        # @param metadata [Array<Hash>] a list of metadata with label and value as required keys for each entry
        # @return [Boolean]
      def valid_metadata_structure?(metadata)
        metadata.is_a?(Array) && metadata.all? { |v| v.is_a?(Hash) }
      end

        # Manifest Metadata Hashes must contain 'label' and 'value' keys
        #
        # @param metadata [Array<Hash>] a list of metadata with label and value as required keys for each entry
        # @return [Boolean]
      def valid_metadata_content?(metadata)
        metadata.all? { |v| v['label'].present? && v['value'].present? }
      end
    end
  end
end
