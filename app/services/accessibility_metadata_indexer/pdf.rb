# frozen_string_literal: true

module AccessibilityMetadataIndexer
  class Pdf < Base
    # This will be called from MonographIndexer. Given that nothing indexed here is crucial to Fulcrum's core features,
    # no errors should be raised that would prevent the Monograph document from being created.
    # For all of the fields here I'll use string (not English text), stored and indexed and use the expected cardinality.
    # This should allow any/all to be used in Blacklight facets.
    def index_reader_ebook_accessibility_metadata
      # TODO: Implement PDF accessibility metadata indexing
      # For now, just set screen_reader_friendly to 'unknown'
      solr_doc['epub_a11y_screen_reader_friendly_ssi'] = 'unknown'
    end

    private

      # These methods are required by the Base class but not yet implemented for PDFs
      # They can be implemented when PDF accessibility metadata extraction is added

      def accessibility_summary
        nil
      end

      def accessibility_features
        nil
      end

      def accessibility_hazard
        nil
      end

      def access_mode
        nil
      end

      def access_mode_sufficient
        nil
      end

      def conforms_to
        nil
      end

      def certified_by
        nil
      end

      def certifier_credential
        nil
      end

      def screen_reader_friendly
        'unknown'
      end
  end
end
