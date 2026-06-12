# frozen_string_literal: true

module AccessibilityMetadataIndexer
  class Pdf < Base
    CONFORMANCE_LABEL_MAP = {
      'PDFUA_1' => 'PDF/UA-1',
      'PDFUA_2' => 'PDF/UA-2',
      'WCAG_2_2' => 'WCAG 2.2 AA'
    }.freeze

    def initialize(file_set_id, solr_doc, press)
      super(file_set_id, solr_doc)
      @press = press
      return unless Settings.pdf_ebook_accessibility_metadata&.dir
      @json_data = find_and_parse_json
    end

    # This will be called from MonographIndexer. Given that nothing indexed here is crucial to Fulcrum's core features,
    # no errors should be raised that would prevent the Monograph document from being created.
    # For all of the fields here I'll use string (not English text), stored and indexed and use the expected cardinality.
    # This should allow any/all to be used in Blacklight facets.
    def index_reader_ebook_accessibility_metadata
      return unless @json_data

      solr_doc['pdf_a11y_document_type_ssi'] = @json_data.dig('document_type', 'document_type')

      solr_doc['pdf_a11y_accessibility_summary_ssi'] = accessibility_summary
      solr_doc['pdf_a11y_accessibility_feature_ssim'] = accessibility_features
      solr_doc['pdf_a11y_accessibility_hazard_ssim'] = accessibility_hazard
      solr_doc['pdf_a11y_access_mode_ssim'] = access_mode
      solr_doc['pdf_a11y_access_mode_sufficient_ssim'] = access_mode_sufficient
      solr_doc['pdf_a11y_conforms_to_ssi'] = conforms_to
      solr_doc['pdf_a11y_certified_by_ssi'] = certified_by
      solr_doc['pdf_a11y_certifier_credential_ssi'] = certifier_credential
      solr_doc['pdf_a11y_screen_reader_friendly_ssi'] = screen_reader_friendly
    end

    private

      def find_and_parse_json
        press_dir = File.join(Settings.pdf_ebook_accessibility_metadata.dir, @press)
        return nil unless Dir.exist?(press_dir)

        checksum = file_set_checksum
        return nil if checksum.blank?

        json_file = File.join(press_dir, "#{checksum}.json")
        return nil unless File.exist?(json_file)

        JSON.parse(File.read(json_file))
      rescue JSON::ParserError
        nil
      end

      def file_set_checksum
        result = ActiveFedora::SolrService.query("{!terms f=id}#{file_set_id}", fl: ['original_checksum_ssim'], rows: 1).first
        result&.dig('original_checksum_ssim')&.first
      end

      def accessibility_summary
        nil
      end

      def accessibility_features
        machine_readable = machine_readable_text_feature
        tagged           = 'Tagged structure' if tagged?
        has_bookmarks    = 'Bookmarks' if bookmarks?
        reading_order    = 'Reading Order Set' if reading_order_set?
        has_alt_text     = 'Alt Text' if alt_text?

        # 'None' is returned only when none of the core PDF accessibility features are present
        core_features = [machine_readable, tagged, has_bookmarks, reading_order, has_alt_text].compact
        return ['None'] if core_features.blank?

        core_features.sort
      end

      def machine_readable_text_feature
        case @json_data.dig('document_type', 'document_type')
        when 'native'
          'Machine-readable text (Embedded)'
        when 'scanned_ocr'
          'Machine-readable text (OCR)'
        end
      end

      def tagged?
        @json_data.dig('metadata', 'is_tagged') == 'true'
      end

      def bookmarks?
        @json_data.dig('bookmarks', 'items').present?
      end

      # TODO: implement when the JSON analysis tool provides a reading order presence flag
      def reading_order_set?
        false
      end

      # TODO: implement when the JSON analysis tool provides an overall alt text presence flag
      def alt_text?
        false
      end

      def accessibility_hazard
        nil
      end

      def access_mode
        case @json_data.dig('document_type', 'document_type')
        when 'native'
          ['textual', 'visual']
        when 'scanned_ocr'
          ['textual', 'visual']
        when 'scanned_unreadable'
          ['visual']
        else
          nil
        end
      end

      def access_mode_sufficient
        case @json_data.dig('document_type', 'document_type')
        when 'native'
          ['textual']
        else
          nil
        end
      end

      def conforms_to
        conformance = @json_data['conformance'] || {}
        passing_labels = conformance.filter_map do |key, value|
          CONFORMANCE_LABEL_MAP[key] if value.is_a?(Hash) && value['status'] == 'pass'
        end
        passing_labels.present? ? passing_labels.join(', ') : nil
      end

      def certified_by
        nil
      end

      def certifier_credential
        nil
      end

      def screen_reader_friendly
        return 'yes' if passes_accessibility_conformance? || all_accessibility_features_present?
        return 'no, but includes some accessibility features' if any_accessibility_feature_present?
        'no'
      end

      # PDF/UA-1, PDF/UA-2, and WCAG 2.2 AA (verapdf does not report WCAG 2.1 separately)
      def passes_accessibility_conformance?
        conformance = @json_data['conformance'] || {}
        %w[PDFUA_1 PDFUA_2 WCAG_2_2].any? { |key| conformance.dig(key, 'status') == 'pass' }
      end

      def all_accessibility_features_present?
        machine_readable_text_feature.present? && tagged? && bookmarks? && reading_order_set? && alt_text?
      end

      def any_accessibility_feature_present?
        machine_readable_text_feature.present? || tagged? || bookmarks? || reading_order_set? || alt_text?
      end
  end
end
