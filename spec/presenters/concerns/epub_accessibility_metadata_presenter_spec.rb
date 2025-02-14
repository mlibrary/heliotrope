# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EpubAccessibilityMetadataPresenter do
  class self::Presenter # rubocop:disable Style/ClassAndModuleChildren
    include EpubAccessibilityMetadataPresenter
    attr_reader :solr_document

    def initialize(solr_document)
      @solr_document = solr_document
    end
  end

  let(:solr_document) { SolrDocument.new({ 'epub_a11y_access_mode_ssim' => epub_a11y_access_mode_ssim,
                                           'epub_a11y_access_mode_sufficient_ssim' => epub_a11y_access_mode_sufficient_ssim,
                                           # see HELIO-4830: we should keep the full and updated list of values to map in here
                                           'epub_a11y_accessibility_feature_ssim' => epub_a11y_accessibility_feature_ssim,
                                           'epub_a11y_accessibility_hazard_ssim' => ['flashing', 'motionSimulation'],
                                           'epub_a11y_accessibility_summary_ssi' => 'A very complex book with 15 images, 10 tables, and complex formatting...',
                                           'epub_a11y_certified_by_ssi' => 'A11yCo',
                                           'epub_a11y_certifier_credential_ssi' => 'https://a11yfoo.org/certification',
                                           'epub_a11y_conforms_to_ssi' => 'EPUB Accessibility 1.1 - WCAG 2.1 Level AA',
                                           'epub_a11y_screen_reader_friendly_ssi' => 'yes' }) }

  let(:epub_a11y_access_mode_ssim) { ['textual', 'visual'] }
  let(:epub_a11y_access_mode_sufficient_ssim) { ['textual', 'textual,visual', 'textual,visual'] }
  let(:epub_a11y_accessibility_feature_ssim) { ['alternativeText',
                                                'annotations',
                                                'ARIA',
                                                'audioDescription',
                                                'braille',
                                                'ChemML',
                                                'closedCaptions',
                                                'describedMath',
                                                'displayTransformability',
                                                'fullRubyAnnotations',
                                                'highContrastAudio',
                                                'highContrastDisplay',
                                                'horizontalWriting',
                                                'index',
                                                'largePrint',
                                                'latex',
                                                'longDescription',
                                                'MathML',
                                                'none',
                                                'openCaptions',
                                                'pageBreakMarkers',
                                                'pageNavigation',
                                                'readingOrder',
                                                'rubyAnnotations',
                                                'structuralNavigation',
                                                'synchronizedAudioText',
                                                'tableOfContents',
                                                'tactileGraphic',
                                                'tactileObject',
                                                'taggedPDF',
                                                'timingControl',
                                                'transcript',
                                                'ttsMarkup',
                                                'unknown',
                                                'unlocked',
                                                'verticalWriting',
                                                'withAdditionalWordSegmentation',
                                                'withoutAdditionalWordSegmentation'] }
  let(:presenter) { self.class::Presenter.new(solr_document) }

  describe 'Presenter' do
    subject { presenter }

    let(:input_title) { double('markdown title') }

    it 'includes EpubAccessibilityMetadataPresenter' do
      is_expected.to be_a described_class
    end
  end

  describe '#epub_a11y_access_modes' do
    subject { presenter.epub_a11y_access_modes }

    it 'outputs the correct field value' do
      is_expected.to eq ['textual', 'visual']
    end
  end

  describe '#epub_a11y_access_modes_sufficient' do
    subject { presenter.epub_a11y_access_modes_sufficient }

    it 'outputs the correct field value' do
      is_expected.to eq ['textual', 'textual,visual', 'textual,visual']
    end
  end

  describe '#epub_a11y_accessibility_features' do
    subject { presenter.epub_a11y_accessibility_features }

    it 'outputs the correctly *MAPPED* field value' do
      is_expected.to eq ['Alternative text for images',
                         'Annotations',
                         'ARIA roles',
                         'Audio description',
                         'Braille',
                         'ChemML markup',
                         'Closed captions',
                         'Textual descriptions for math equations',
                         'Display transformability of text',
                         'Ruby annotations for all language pronunciation',
                         'Audio with low or no background noise',
                         'High contrast text',
                         'Horizontal writing',
                         'Index',
                         'Formatted to meet large print guidelines',
                         'Math equations formatted with LaTeX',
                         'Textual descriptions of complex content',
                         'MathML markup',
                         'None',
                         'Open captions',
                         'Page numbers',
                         'Page list navigation aid',
                         'Logical reading order',
                         'Ruby annotation for some language pronounciation',
                         'Correct use of heading levels',
                         'Synchronized playback for prerecorded audio with text highlighting',
                         'Table of Contents',
                         'Access to tactile graphics',
                         'Includes tactile objects',
                         'Accessibility tags to improve readability',
                         'Content with timed interactions that can be controlled by the user',
                         'Transcripts for audio content',
                         'Phonetic markup to improve text-to-speech playback',
                         'Accessibility features unknown',
                         'No digital rights management (DRM)',
                         'Vertical writing',
                         'Additional word segmentation to improve readability',
                         'No additional word segmentation']
    end
  end

  describe '#epub_a11y_accessibility_hazards' do
    subject { presenter.epub_a11y_accessibility_hazards }

    it 'outputs the correct field value' do
      is_expected.to eq ['flashing', 'motionSimulation']
    end
  end

  describe '#epub_a11y_accessibility_summary' do
    subject { presenter.epub_a11y_accessibility_summary }

    it 'outputs the correct field value' do
      is_expected.to eq 'A very complex book with 15 images, 10 tables, and complex formatting...'
    end
  end

  describe '#epub_a11y_certified_by' do
    subject { presenter.epub_a11y_certified_by }

    it 'outputs the correct field value' do
      is_expected.to eq 'A11yCo'
    end
  end

  describe '#epub_a11y_certifier_credential' do
    subject { presenter.epub_a11y_certifier_credential }

    it 'outputs the correct field value' do
      is_expected.to eq 'https://a11yfoo.org/certification'
    end
  end

  describe '#epub_a11y_conforms_to' do
    subject { presenter.epub_a11y_conforms_to }

    it 'outputs the correct field value' do
      is_expected.to eq 'EPUB Accessibility 1.1 - WCAG 2.1 Level AA'
    end
  end

  describe '#epub_a11y_screen_reader_friendly' do
    subject { presenter.epub_a11y_screen_reader_friendly }

    it 'outputs the correct field value' do
      is_expected.to eq 'yes'
    end
  end

  describe '#hidden_a11y_data_is_present?' do
    subject { presenter.hidden_a11y_data_is_present? }

    it 'is true when all of the three hidden fields are present' do
      is_expected.to eq true
    end

    context 'only `epub_a11y_access_mode_ssim` is present' do
      let(:epub_a11y_access_mode_ssim) { ['textual', 'visual'] }
      let(:epub_a11y_access_mode_sufficient_ssim) { nil }
      let(:epub_a11y_accessibility_feature_ssim) { nil }

      it 'is true' do
        is_expected.to eq true
      end
    end

    context 'only `epub_a11y_access_mode_sufficient_ssim` is present' do
      let(:epub_a11y_access_mode_ssim) { nil }
      let(:epub_a11y_access_mode_sufficient_ssim) { ['textual', 'textual,visual', 'textual,visual'] }
      let(:epub_a11y_accessibility_feature_ssim) { nil }

      it 'is true' do
        is_expected.to eq true
      end
    end

    context 'only `epub_a11y_access_mode_ssim` is present' do
      let(:epub_a11y_access_mode_ssim) { nil }
      let(:epub_a11y_access_mode_sufficient_ssim) { nil }
      let(:epub_a11y_accessibility_feature_ssim) { ['alternativeText'] }
      it 'is true' do
        is_expected.to eq true
      end
    end

    context 'none of the three hidden fields are present' do
      let(:epub_a11y_access_mode_ssim) { nil }
      let(:epub_a11y_access_mode_sufficient_ssim) { nil }
      let(:epub_a11y_accessibility_feature_ssim) { nil }

      it 'is true' do
        is_expected.to eq false
      end
    end
  end
end
