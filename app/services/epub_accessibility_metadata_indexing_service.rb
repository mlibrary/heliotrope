# frozen_string_literal: true

class EpubAccessibilityMetadataIndexingService
  class << self
    # This will be called from MonographIndexer. Given that nothing indexed here is crucial to Fulcrum's core features,...
    # no errors should be raised that would prevent the Monograph document from being created.
    # For all of the fields here I'll use string (not English text), stored and indexed and use the expected cardinality.
    # This should allow any/all to be used in Blacklight facets.
    def index(epub_file_set_id, solr_doc)
      root_path = UnpackService.root_path_from_noid(epub_file_set_id, 'epub')
      return unless Dir.exist? root_path

      container_file = File.join(root_path, "META-INF/container.xml")
      return unless File.exist? container_file

      container = Nokogiri::XML(File.open(container_file)).remove_namespaces!
      container.xpath("//rootfile").length > 1 ? 'yes' : 'no'
      # Accessibility metadata extraction requires one, and only one, rendition to be present.
      return unless container.xpath("//rootfile").length == 1

      content_file = container.xpath("//rootfile/@full-path").text
      content_file = File.join(root_path, content_file)
      return unless File.exist? content_file

      content = Nokogiri::XML(File.open(content_file)).remove_namespaces!
      package_element = content.at_css('package')
      epub_version = package_element['version']&.strip if package_element.present?
      return if epub_version.blank?

      # Indexing this for no particular reason. Might be useful at some point.
      solr_doc['epub_version_ssi'] = epub_version

      # This should allow the relevant values to be detected for both EPUB 2 and EPUB 3, though only the latter should...
      # be present on Fulcrum. See Daisy links below.
      @epub_2 = epub_version.start_with?('2')
      @meta_attribute = @epub_2 ? 'name' : 'property'

      @content_metadata = content.at_css('metadata')
      return if @content_metadata.blank?

      # for these schema values see https://kb.daisy.org/publishing/docs/metadata/schema.org/
      solr_doc['epub_a11y_accessibility_summary_ssi'] = accessibility_summary
      solr_doc['epub_a11y_accessibility_features_ssim'] = accessibility_features
      solr_doc['epub_a11y_access_mode_ssim'] = access_mode
      @access_mode_sufficient = access_mode_sufficient
      solr_doc['epub_a11y_access_mode_sufficient_ssim'] = @access_mode_sufficient

      # for these evaluation values see https://kb.daisy.org/publishing/docs/metadata/evaluation.html
      solr_doc['epub_a11y_conforms_to_ssi'] = conforms_to
      solr_doc['epub_a11y_certified_by_ssi'] = certified_by
      solr_doc['epub_a11y_certifier_credential_ssi'] = certifier_credential

      # This is a derived value for convenience in Fulcrum UI use.
      solr_doc['epub_a11y_screen_reader_friendly_ssi'] = screen_reader_friendly
    end

    def accessibility_summary
      value = @content_metadata.at_css("meta[#{@meta_attribute}='schema:accessibilitySummary']")
      return nil if value.blank?
      @epub_2 ? value['content']&.strip : value.text&.strip
    end

    def accessibility_features
      # this involves multiple entries in separate meta tags
      values = @content_metadata.css("meta[#{@meta_attribute}='schema:accessibilityFeature']")

      values = if @epub_2
                 values&.map { |value| value['content']&.strip }
               else
                 values&.map { |value| value&.text&.strip }
               end
      # want to ensure the indexer is set to nil not [] if these are not present, keeping the field off the doc entirely
      values.presence
    end

    def access_mode
      # this involves multiple entries in separate meta tags
      values = @content_metadata.css("meta[#{@meta_attribute}='schema:accessMode']")

      values = if @epub_2
                 values&.map { |value| value['content']&.strip }
               else
                 values&.map { |value| value&.text&.strip }
               end
      # want to ensure the indexer is set to nil not [] if these are not present, keeping the field off the doc entirely
      values.presence
    end

    def access_mode_sufficient
      # this one has multiple entries in one value, comma separated
      values = @content_metadata.at_css("meta[#{@meta_attribute}='schema:accessModeSufficient']")
      return nil if values.blank?
      values = @epub_2 ? values['content']&.split(',') : values.text&.split(',')
      values&.reject(&:blank?)&.map(&:strip)
    end

    def conforms_to
      value = @content_metadata.at_css("meta[#{@meta_attribute}='dcterms:conformsTo']")
      return nil if value.blank?
      @epub_2 ? value['content']&.strip : value.text&.strip
    end

    def certified_by
      value = @content_metadata.at_css("meta[#{@meta_attribute}='a11y:certifiedBy']")
      return nil if value.blank?
      @epub_2 ? value['content']&.strip : value.text&.strip
    end

    def certifier_credential
      value = @content_metadata.at_css("meta[#{@meta_attribute}='a11y:certifierCredential']")
      return nil if value.blank?
      @epub_2 ? value['content']&.strip : value.text&.strip
    end

    def screen_reader_friendly
      if @access_mode_sufficient.present?
        if @access_mode_sufficient.count == 1 && @access_mode_sufficient[0] == 'textual'
          'true'
        else
          'false'
        end
      else
        # I guess it's OK that this will always have a value even if all the other a11y metadata is missing.
        'unknown'
      end
    end
  end
end
