# frozen_string_literal: true

module AccessibilityMetadataIndexer
  class Epub < Base
    # This is a map of the values in the `accessibilityFeature` meta tag to the corresponding human-readable text.
    # See https://kb.daisy.org/publishing/docs/metadata/schema.org/accessibilityFeature.html
    # We may need to schedule updates to this list as the schema.org list grows.
    A11Y_FEATURES_MAP = { 'alternativeText' => 'Alternative text for images',
                          'annotations' => 'Annotations',
                          'ARIA' => 'ARIA roles',
                          'audioDescription' => 'Audio description',
                          'bookmarks' => 'Bookmarks', # this is deprecated and shouldn't appear in EPUB metadata
                          'braille' => 'Braille',
                          'captions' => 'Captions', # this is deprecated and shouldn't appear in EPUB metadata
                          'ChemML' => 'ChemML markup',
                          'closedCaptions' => 'Closed captions',
                          'describedMath' => 'Textual descriptions for math equations',
                          'displayTransformability' => 'Display transformability of text',
                          'fullRubyAnnotations' => 'Ruby annotations for all language pronunciation',
                          'highContrastAudio' => 'Audio with low or no background noise',
                          'highContrastDisplay' => 'High contrast text',
                          'horizontalWriting' => 'Horizontal writing',
                          'index' => 'Index',
                          'largePrint' => 'Formatted to meet large print guidelines',
                          'latex' => 'Math equations formatted with LaTeX',
                          'longDescription' => 'Textual descriptions of complex content',
                          'MathML' => 'MathML markup',
                          'none' => 'None',
                          'openCaptions' => 'Open captions',
                          'pageBreakMarkers' => 'Page numbers',
                          'printPageNumbers' => 'Page numbers', # considered a quasi-deprecated synonym of `pageBreakMarkers`
                          'pageNavigation' => 'Page list navigation aid',
                          'readingOrder' => 'Logical reading order',
                          'rubyAnnotations' => 'Ruby annotation for some language pronunciation',
                          'structuralNavigation' => 'Correct use of heading levels',
                          'synchronizedAudioText' => 'Synchronized playback for prerecorded audio with text highlighting',
                          'tableOfContents' => 'Table of Contents',
                          'tactileGraphic' => 'Access to tactile graphics',
                          'tactileObject' => 'Includes tactile objects',
                          'taggedPDF' => 'Accessibility tags to improve readability',
                          'timingControl' => 'Content with timed interactions that can be controlled by the user',
                          'transcript' => 'Transcripts for audio content',
                          'ttsMarkup' => 'Phonetic markup to improve text-to-speech playback',
                          'unknown' => 'Accessibility features unknown',
                          'unlocked' => 'No digital rights management (DRM)',
                          'verticalWriting' => 'Vertical writing',
                          'withAdditionalWordSegmentation' => 'Additional word segmentation to improve readability',
                          'withoutAdditionalWordSegmentation' => 'No additional word segmentation' }

    # This will be called from MonographIndexer. Given that nothing indexed here is crucial to Fulcrum's core features,
    # no errors should be raised that would prevent the Monograph document from being created.
    # For all of the fields here I'll use string (not English text), stored and indexed and use the expected cardinality.
    # This should allow any/all to be used in Blacklight facets.
    def index_reader_ebook_accessibility_metadata
      root_path = UnpackService.root_path_from_noid(file_set_id, 'epub')
      return unless Dir.exist? root_path

      container_file = File.join(root_path, "META-INF/container.xml")
      return unless File.exist? container_file

      container = Nokogiri::XML(File.read(container_file)).remove_namespaces!
      rootfiles = container.xpath("//rootfile")
      # Accessibility metadata extraction requires one, and only one, rendition to be present.
      return unless rootfiles.length == 1

      content_file = rootfiles.attr('full-path').text
      content_file = File.join(root_path, content_file)
      return unless File.exist? content_file

      content = Nokogiri::XML(File.read(content_file)).remove_namespaces!
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
      solr_doc['epub_a11y_accessibility_feature_ssim'] = accessibility_features
      solr_doc['epub_a11y_accessibility_hazard_ssim'] = accessibility_hazard
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

    private

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
        # note: `|| value` means we'll just use the value itself if it isn't found as a key in `A11Y_FEATURES_MAP`
        values.presence&.map { |value| A11Y_FEATURES_MAP[value] || value }&.uniq&.sort
      end

      def accessibility_hazard
        # this involves multiple entries in separate meta tags
        values = @content_metadata.css("meta[#{@meta_attribute}='schema:accessibilityHazard']")

        values = if @epub_2
                   values&.map { |value| value['content']&.strip }
                 else
                   values&.map { |value| value&.text&.strip }
                 end
        # want to ensure the indexer is set to nil not [] if these are not present, keeping the field off the doc entirely
        values.presence&.sort
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
        values.presence&.sort
      end

      def access_mode_sufficient
        # this one has multiple entries in separate meta tags, each of which can have one or more comma-separated values in it
        values = @content_metadata.css("meta[#{@meta_attribute}='schema:accessModeSufficient']")

        values = if @epub_2
                   values&.map { |value| value['content']&.strip }
                 else
                   values&.map { |value| value&.text&.strip }
                 end
        # want to ensure the indexer is set to nil not [] if these are not present, keeping the field off the doc entirely
        values.presence&.sort
      end

      def conforms_to
        # need to check for both the EPUB Accessibility 1.1 style and the older 1.0 style, see:
        # https://kb.daisy.org/publishing/docs/metadata/evaluation.html#a11y-transition

        # check for 1.1 first
        value = @content_metadata.at_css("meta[#{@meta_attribute}='dcterms:conformsTo']")

        value = if value.present?
                  @epub_2 ? value['content']&.strip : value.text&.strip
                end
        return value if value.present?

        # look for EPUB Accessibility 1.0 style instead
        value = @content_metadata.at_css("link[rel='dcterms:conformsTo']")
        value = value['href']&.strip if value.present?

        return nil if value.blank?
        value
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
          if @access_mode_sufficient.any? { |value| value == 'textual' }
            'yes'
          else
            'no'
          end
        else
          # I guess it's OK that this will always have a value even if all the other a11y metadata is missing.
          'unknown'
        end
      end
  end
end
