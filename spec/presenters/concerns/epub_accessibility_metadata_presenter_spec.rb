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
                                           'epub_a11y_certified_by_ssi' => epub_a11y_certified_by_ssi,
                                           'epub_a11y_certifier_credential_ssi' => epub_a11y_certifier_credential_ssi,
                                           'epub_a11y_conforms_to_ssi' => epub_a11y_conforms_to_ssi,
                                           'epub_a11y_screen_reader_friendly_ssi' => epub_a11y_screen_reader_friendly_ssi }) }

  let(:epub_a11y_access_mode_ssim) { ['textual', 'visual'] }
  let(:epub_a11y_access_mode_sufficient_ssim) { ['textual', 'textual,visual', 'textual,visual'] }
  let(:epub_a11y_accessibility_feature_ssim) { ['alternativeText',
                                                'annotations',
                                                'ARIA',
                                                'audioDescription',
                                                'bookmarks',
                                                'braille',
                                                'captions',
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
                                                'printPageNumbers',
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
                                                'withoutAdditionalWordSegmentation',
                                                # this is to test that unmapped values are retained in the output of...
                                                # `epub_a11y_accessibility_features`
                                                'unknownRandomValue'] }
  let(:epub_a11y_certified_by_ssi) { 'A11yCo' }
  let(:epub_a11y_certifier_credential_ssi) { 'https://a11yfoo.org/certification' }
  let(:epub_a11y_conforms_to_ssi) { 'EPUB Accessibility 1.1 - WCAG 2.1 Level AA' }
  let(:epub_a11y_screen_reader_friendly_ssi) { 'yes' }
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
                         'Bookmarks',
                         'Braille',
                         'Captions',
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
                         'No additional word segmentation',
                         'unknownRandomValue']
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

  describe 'Accessibility Certification (organization and authority)' do
    describe '#epub_a11y_certified_by' do
      subject { presenter.epub_a11y_certified_by }

      context 'value is *not* "Benetech"' do
        context 'epub_a11y_certifier_credential value is a link' do
          it 'outputs the field value' do
            is_expected.to eq 'A11yCo'
          end
        end

        context 'epub_a11y_certifier_credential value is *not* a link' do
          let(:epub_a11y_certifier_credential_ssi) { 'Certification' }

          it 'outputs the field value' do
            is_expected.to eq 'A11yCo'
          end
        end
      end

      context 'value is "Benetech"' do
        let(:epub_a11y_certified_by_ssi) { 'Benetech' }

        context 'epub_a11y_certifier_credential value is a link' do
          it 'outputs nothing as this will be combined with the certifier credential value instead' do
            is_expected.to be_nil
          end
        end

        context 'epub_a11y_certifier_credential value is *not* a link' do
          let(:epub_a11y_certifier_credential_ssi) { 'Certification' }

          it 'outputs the field value' do
            is_expected.to eq 'Benetech'
          end
        end
      end
    end

    describe '#epub_a11y_certifier_credential' do
      subject { presenter.epub_a11y_certifier_credential }

      context 'epub_a11y_certifier_credential value is a link' do
        context 'epub_a11y_certified_by_ssi value is *not* "Benetech"' do
          it 'outputs the link as-is' do
            is_expected.to eq '<a href="https://a11yfoo.org/certification" target="_blank">https://a11yfoo.org/certification</a>'
          end
        end

        context 'epub_a11y_certified_by value is "Benetech"' do
          let(:epub_a11y_certified_by_ssi) { 'Benetech' }

          context 'epub_a11y_certifier_credential value is a link' do
            let(:epub_a11y_certifier_credential_ssi) { 'Certification' }

            it 'outputs the link with Benetech text' do
              '<a href="https://a11yfoo.org/certification" target="_blank">GCA Certified by Benetech</a>'
            end
          end
        end
      end

      context 'epub_a11y_certifier_credential value is *not"" a link' do
        let(:epub_a11y_certifier_credential_ssi) { 'Certification' }

        context 'epub_a11y_certified_by value is *not* "Benetech"' do
          it 'outputs the value as-is' do
            is_expected.to eq 'Certification'
          end
        end

        context 'epub_a11y_certified_by value is "Benetech"' do
          let(:epub_a11y_certified_by_ssi) { 'Benetech' }

          context 'epub_a11y_certifier_credential value is a link' do
            it 'outputs the value as-is' do
              is_expected.to eq 'Certification'
            end
          end
        end
      end
    end
  end

  describe '#epub_a11y_conforms_to' do
    subject { presenter.epub_a11y_conforms_to }

    describe "EPUB Accessibility 1.0 specification links (there are seemingly many but we'll check two)" do
      it 'outputs the field value' do
        is_expected.to eq 'EPUB Accessibility 1.1 - WCAG 2.1 Level AA'
      end

      context 'Proposed Specification 30 November 2016 links' do
        context 'Level A' do
          let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20160801.html#wcag-a' }

          it 'outputs the correct named link' do
            is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level A conformance</a>.'.html_safe
          end
        end

        context 'Level AA' do
          let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20160801.html#wcag-aa' }

          it 'outputs the correct named link' do
            is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level AA conformance</a>.'.html_safe
          end
        end

        context 'Level AA' do
          let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20160801.html#wcag-aaa' }

          it 'outputs the correct named link' do
            is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20160801.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level AAA conformance</a>.'.html_safe
          end
        end
      end
    end

    context 'Recommended Specification 5 January 2017 links' do
      context 'Level A' do
        let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-a' }

        it 'outputs the correct named link' do
          is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level A conformance</a>.'.html_safe
        end
      end

      context 'Level AA' do
        let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aa' }

        it 'outputs the correct named link' do
          is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level AA conformance</a>.'.html_safe
        end
      end

      context 'Level AA' do
        let(:epub_a11y_conforms_to_ssi) { 'https://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aaa' }

        it 'outputs the correct named link' do
          is_expected.to eq 'The EPUB Publication meets all <a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#sec-conf-epub" target="_blank">accessibility requirements</a> and achieves [<a href="https://www.idpf.org/epub/a11y/accessibility-20170105.html#refWCAG20" target="_blank">WCAG 2.0</a>] <a href="https://www.w3.org/TR/WCAG20/#conformance-reqs" target="_blank">Level AAA conformance</a>.'.html_safe
        end
      end
    end
  end

  describe '#epub_a11y_screen_reader_friendly' do
    subject { presenter.epub_a11y_screen_reader_friendly }

    context '`epub_a11y_screen_reader_friendly_ssi` has a value other than "unknown"' do
      it 'outputs the correct field value' do
        is_expected.to eq 'yes'
      end
    end

    context '`epub_a11y_screen_reader_friendly_ssi` has a value of "unknown"' do
      let(:epub_a11y_screen_reader_friendly_ssi) { 'unknown' }

      it 'outputs the correct field value' do
        is_expected.to eq 'No information is available'
      end
    end

    context '`epub_a11y_screen_reader_friendly_ssi` is not present' do
      let(:epub_a11y_screen_reader_friendly_ssi) { nil }

      it 'outputs the correct field value' do
        is_expected.to eq 'No information is available'
      end
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
