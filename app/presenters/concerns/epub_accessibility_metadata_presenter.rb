# frozen_string_literal: true

module EpubAccessibilityMetadataPresenter
  extend ActiveSupport::Concern

  A11Y_FEATURES_MAP = { 'alternativeText' => 'Alternative text for images',
                        'annotations' => 'Annotations',
                        'ARIA' => 'ARIA roles',
                        'audioDescription' => 'Audio description',
                        'braille' => 'Braille',
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

  def epub_a11y_accessibility_features
    @epub_a11y_accessibility_features ||=
      solr_document['epub_a11y_accessibility_feature_ssim']&.map { |value| A11Y_FEATURES_MAP[value] }
  end

  def epub_a11y_accessibility_hazards
    solr_document['epub_a11y_accessibility_hazard_ssim']
  end

  def epub_a11y_accessibility_summary
    solr_document['epub_a11y_accessibility_summary_ssi']
  end

  def epub_a11y_certified_by
    solr_document['epub_a11y_certified_by_ssi']
  end

  def epub_a11y_certifier_credential
    solr_document['epub_a11y_certifier_credential_ssi']
  end

  def epub_a11y_conforms_to
    solr_document['epub_a11y_conforms_to_ssi']
  end

  def epub_a11y_screen_reader_friendly
    solr_document['epub_a11y_screen_reader_friendly_ssi']
  end

  def hidden_a11y_data_is_present?
    epub_a11y_access_modes_sufficient.present? || epub_a11y_access_modes.present? || epub_a11y_accessibility_features.present?
  end
end
