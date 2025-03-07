# frozen_string_literal: true

module EpubAccessibilityMetadataPresenter
  extend ActiveSupport::Concern
  include Skylight::Helpers

  A11Y_FEATURES_MAP = { 'alternativeText' => 'Alternative text for images',
                        'annotations' => 'Annotations',
                        'ARIA' => 'ARIA roles',
                        'audioDescription' => 'Audio description',
                        'bookmarks' => 'Bookmarks', # this is deprecated and shouldn't appear in EPUB metadata
                        'braille' => 'Braille',
                        "captions" => 'Captions', # this is deprecated and shouldn't appear in EPUB metadata
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
                        'rubyAnnotations' => 'Ruby annotation for some language pronounciation',
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

  def epub_a11y_access_modes
    solr_document['epub_a11y_access_mode_ssim']
  end

  def epub_a11y_access_modes_sufficient
    solr_document['epub_a11y_access_mode_sufficient_ssim']
  end

  instrument_method
  def epub_a11y_accessibility_features
    # note: `|| value` means we'll just show the value itself if it isn't found as a key in `A11Y_FEATURES_MAP`
    @epub_a11y_accessibility_features ||=
      solr_document['epub_a11y_accessibility_feature_ssim']&.map { |value| A11Y_FEATURES_MAP[value] || value }&.uniq
  end

  def epub_a11y_accessibility_hazards
    solr_document['epub_a11y_accessibility_hazard_ssim']
  end

  def epub_a11y_accessibility_summary
    solr_document['epub_a11y_accessibility_summary_ssi']
  end

  def epub_a11y_certified_by
    @epub_a11y_certified_by ||= if solr_document['epub_a11y_certifier_credential_ssi']&.start_with?('http')
                                  if solr_document['epub_a11y_certified_by_ssi']&.downcase == 'benetech'
                                    nil
                                  else
                                    solr_document['epub_a11y_certified_by_ssi'].presence
                                  end
                                else
                                  solr_document['epub_a11y_certified_by_ssi']&.presence
                                end
  end

  def epub_a11y_certifier_credential
    @epub_a11y_certifier_credential ||= if solr_document['epub_a11y_certifier_credential_ssi']&.start_with?('http')
                                          if solr_document['epub_a11y_certified_by_ssi']&.downcase == 'benetech'
                                            "<a href=\"#{solr_document['epub_a11y_certifier_credential_ssi']}\" target=\"_blank\">GCA Certified by Benetech</a>"
                                          else
                                            "<a href=\"#{solr_document['epub_a11y_certifier_credential_ssi']}\" target=\"_blank\">#{solr_document['epub_a11y_certifier_credential_ssi']}</a>"
                                          end
                                        else
                                          solr_document['epub_a11y_certifier_credential_ssi']&.presence
                                        end
  end

  instrument_method
  def epub_a11y_conforms_to
    @epub_a11y_conforms_to ||= if solr_document['epub_a11y_conforms_to_ssi']&.downcase&.end_with?('#wcag-a')
                                 "The EPUB Publication meets all <a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-a', '')}#sec-conf-epub\" target=\"_blank\">accessibility requirements</a> and achieves [<a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-a', '')}#refWCAG20\" target=\"_blank\">WCAG 2.0</a>] <a href=\"https://www.w3.org/TR/WCAG20/#conformance-reqs\" target=\"_blank\">Level A conformance</a>.".html_safe # rubocop:disable Rails/OutputSafety
                               elsif solr_document['epub_a11y_conforms_to_ssi']&.downcase&.end_with?('#wcag-aa')
                                 "The EPUB Publication meets all <a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-aa', '')}#sec-conf-epub\" target=\"_blank\">accessibility requirements</a> and achieves [<a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-aa', '')}#refWCAG20\" target=\"_blank\">WCAG 2.0</a>] <a href=\"https://www.w3.org/TR/WCAG20/#conformance-reqs\" target=\"_blank\">Level AA conformance</a>.".html_safe # rubocop:disable Rails/OutputSafety
                               elsif solr_document['epub_a11y_conforms_to_ssi']&.downcase&.end_with?('#wcag-aaa')
                                 "The EPUB Publication meets all <a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-aaa', '')}#sec-conf-epub\" target=\"_blank\">accessibility requirements</a> and achieves [<a href=\"#{solr_document['epub_a11y_conforms_to_ssi'].gsub('#wcag-aaa', '')}#refWCAG20\" target=\"_blank\">WCAG 2.0</a>] <a href=\"https://www.w3.org/TR/WCAG20/#conformance-reqs\" target=\"_blank\">Level AAA conformance</a>.".html_safe # rubocop:disable Rails/OutputSafety
                               else
                                 solr_document['epub_a11y_conforms_to_ssi'].presence
                               end
  end

  def epub_a11y_screen_reader_friendly
    value = solr_document['epub_a11y_screen_reader_friendly_ssi']
    # The "Accessibility Claims" tab will show if either an `epub` or `pdf_ebook` representative is present. For now,...
    # no PDFs will offer any accessibility metadata. Some corner-case EPUBs might not have any either.
    # This method always returns a value, which conveniently means the tab will never be empty, even if something...
    # goes awry with the indexing of `epub_a11y_screen_reader_friendly_ssi`, which we also ensure happens for...
    # "reader ebook" Monographs for faceting purposes. See `MonographIndexer.maybe_index_accessibility_metadata()`
    @epub_a11y_screen_reader_friendly ||= if value.blank? || value == 'unknown'
                                            'No information is available'
                                          else
                                            value
                                          end
  end

  def hidden_a11y_data_is_present?
    epub_a11y_access_modes_sufficient.present? || epub_a11y_access_modes.present? || epub_a11y_accessibility_features.present?
  end
end
