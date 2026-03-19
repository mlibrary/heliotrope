# frozen_string_literal: true

module AccessibilityMetadataIndexer
  class Base
    attr_reader :file_set_id, :solr_doc

    def initialize(file_set_id, solr_doc)
      @file_set_id = file_set_id
      @solr_doc = solr_doc
    end

    # This will be called from MonographIndexer. Given that nothing indexed here is crucial to Fulcrum's core features,
    # no errors should be raised that would prevent the Monograph document from being created.
    # For all of the fields here I'll use string (not English text), stored and indexed and use the expected cardinality.
    # This should allow any/all to be used in Blacklight facets.
    def index_reader_ebook_accessibility_metadata
      raise NotImplementedError, "#{self.class} must implement #index_reader_ebook_accessibility_metadata"
    end

    private

      def accessibility_summary
        raise NotImplementedError, "#{self.class} must implement #accessibility_summary"
      end

      def accessibility_features
        raise NotImplementedError, "#{self.class} must implement #accessibility_features"
      end

      def accessibility_hazard
        raise NotImplementedError, "#{self.class} must implement #accessibility_hazard"
      end

      def access_mode
        raise NotImplementedError, "#{self.class} must implement #access_mode"
      end

      def access_mode_sufficient
        raise NotImplementedError, "#{self.class} must implement #access_mode_sufficient"
      end

      def conforms_to
        raise NotImplementedError, "#{self.class} must implement #conforms_to"
      end

      def certified_by
        raise NotImplementedError, "#{self.class} must implement #certified_by"
      end

      def certifier_credential
        raise NotImplementedError, "#{self.class} must implement #certifier_credential"
      end

      def screen_reader_friendly
        raise NotImplementedError, "#{self.class} must implement #screen_reader_friendly"
      end
  end
end
