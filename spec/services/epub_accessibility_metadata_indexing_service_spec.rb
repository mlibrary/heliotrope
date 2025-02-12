# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EpubAccessibilityMetadataIndexingService do
  let(:epub) { create(:public_file_set) }
  let(:unpacked_epub_dir) { UnpackService.root_path_from_noid(epub.id, 'epub') }
  let(:epub_container_file_path) { File.join(unpacked_epub_dir, "META-INF/container.xml") }
  let(:epub_content_file_path) { File.join(unpacked_epub_dir, "OEBPS/content.opf") }
  let(:epub_container_file) { nil }

  # some meaningful content here to show nothing is indexed when problems exist with the container file
  let(:epub_content_file) do
    <<~XML
      <package version="3.0">
        <metadata>
          <meta property="schema:accessibilitySummary">I am here to act as one indexable a11y entry.</meta>
        </metadata>
      </package>
    XML
  end

  # assertions will just check changes to this Solr-doc-representing hash
  let(:epub_solr_doc) { {} }

  before do
    stub_out_redis
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(unpacked_epub_dir).and_return(true)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(epub_container_file_path).and_return(true)
    allow(File).to receive(:exist?).with(epub_content_file_path).and_return(true)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(epub_container_file_path).and_return(epub_container_file)
    allow(File).to receive(:open).with(epub_content_file_path).and_return(epub_content_file)
  end

  describe "Indexing EPUB accessibility metadata" do
    context 'no deriv folder' do
      before do
        allow(Dir).to receive(:exist?).with(unpacked_epub_dir).and_return(false)
      end

      it 'indexes nothing' do
        described_class.index(epub.id, epub_solr_doc)
        expect(epub_solr_doc).to be_empty
      end
    end

    context 'no container file' do
      before do
        allow(File).to receive(:exist?).with(epub_container_file_path).and_return(false)
      end

      it 'indexes nothing' do
        described_class.index(epub.id, epub_solr_doc)
        expect(epub_solr_doc).to be_empty
      end
    end

    context 'empty container file' do
      let(:epub_container_file) { nil }

      it 'indexes nothing' do
        described_class.index(epub.id, epub_solr_doc)
        expect(epub_solr_doc).to be_empty
      end
    end

    context 'multi-rendition container file' do
      let(:epub_container_file) do
        <<~XML
          <?xml version="1.0"?>
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
              <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
                <rootfile full-path="OEBPS/content_page_image.opf" media-type="application/oebps-package+xml"/>
              </rootfiles>
            </container>
          </xml>
        XML
      end

      it 'indexes nothing' do
        described_class.index(epub.id, epub_solr_doc)
        expect(epub_solr_doc).to be_empty
      end
    end

    context 'single rendition container file' do
      let(:epub_container_file) do
        <<~XML
          <?xml version="1.0"?>
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
              <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
              </rootfiles>
            </container>
          </xml>
        XML
      end

      context 'with a missing content file' do
        before do
          allow(File).to receive(:exist?).with(epub_content_file_path).and_return(false)
        end

        it 'indexes nothing' do
          described_class.index(epub.id, epub_solr_doc)
          expect(epub_solr_doc).to be_empty
        end
      end

      context 'with an empty content file' do
        let(:epub_content_file) { nil }

        it 'indexes nothing' do
          described_class.index(epub.id, epub_solr_doc)
          expect(epub_solr_doc).to be_empty
        end
      end

      context 'with a content file with no metadata elements' do
        let(:epub_content_file) { nil }

        it 'indexes nothing' do
          described_class.index(epub.id, epub_solr_doc)
          expect(epub_solr_doc).to be_empty
        end
      end

      context 'content file missing epub version' do
        let(:epub_content_file) do
          <<~XML
            <package>
              <metadata>
                <meta property="schema:accessibilitySummary">I am here to act as one indexable a11y entry.</meta>
              </metadata>
            </package>
          XML
        end

        it 'indexes nothing' do
          described_class.index(epub.id, epub_solr_doc)
          expect(epub_solr_doc).to be_empty
        end
      end

      let(:missing_a11y_metadata_doc_sans_epub_version) { { "epub_a11y_access_mode_ssim" => nil,
                                                            "epub_a11y_access_mode_sufficient_ssim" => nil,
                                                            "epub_a11y_accessibility_feature_ssim" => nil,
                                                            "epub_a11y_accessibility_hazard_ssim" => nil,
                                                            "epub_a11y_accessibility_summary_ssi" => nil,
                                                            "epub_a11y_certified_by_ssi" => nil,
                                                            "epub_a11y_certifier_credential_ssi" => nil,
                                                            "epub_a11y_conforms_to_ssi" => nil,
                                                            "epub_a11y_screen_reader_friendly_ssi" => "unknown" } }

      let(:all_a11y_metadata_doc_sans_epub_version) { { "epub_a11y_access_mode_ssim" => ["textual", "visual"],
                                                        "epub_a11y_access_mode_sufficient_ssim" => ["textual",
                                                                                                    "textual,visual",
                                                                                                    "textual,visual"],
                                                        "epub_a11y_accessibility_feature_ssim" => ["ARIA",
                                                                                                   "alternativeText",
                                                                                                   "displayTransformability",
                                                                                                   "index",
                                                                                                   "pageBreakMarkers",
                                                                                                   "pageNavigation",
                                                                                                   "printPageNumbers",
                                                                                                   "readingOrder",
                                                                                                   "structuralNavigation",
                                                                                                   "tableOfContents"],
                                                        "epub_a11y_accessibility_hazard_ssim" => ["flashing",
                                                                                                  "motionSimulation"],
                                                        "epub_a11y_accessibility_summary_ssi" => "A very complex book with 15 images, 10 tables, and complex formatting...",
                                                        "epub_a11y_certified_by_ssi" => "A11yCo",
                                                        "epub_a11y_certifier_credential_ssi" => "https://a11yfoo.org/certification",
                                                        "epub_a11y_conforms_to_ssi" => "EPUB Accessibility 1.1 - WCAG 2.1 Level AA",
                                                        "epub_a11y_screen_reader_friendly_ssi" => "yes" } }

      context 'EPUB 3.0 content file' do
        context 'no a11y metadata present' do
          let(:epub_content_file) do
            <<~XML
              <package version="3.0">
                <metadata>
                  <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                </metadata>
              </package>
            XML
          end

          it 'only indexes epub_version_ssi and the derived epub_a11y_screen_reader_friendly_ssi field' do
            described_class.index(epub.id, epub_solr_doc)
            expect(epub_solr_doc).to eq(missing_a11y_metadata_doc_sans_epub_version.merge({ "epub_version_ssi" => "3.0" }))
          end
        end

        context 'all a11y metadata present' do
          let(:epub_content_file) do
            <<~XML
              <package version="3.0">
                <metadata>
                  <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                  <meta property="schema:accessMode">textual</meta>
                  <meta property="schema:accessMode">visual</meta>
                  <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                  <meta property="schema:accessModeSufficient">textual,visual</meta>
                  <meta property="schema:accessModeSufficient">textual</meta>
                  <meta property="schema:accessibilityFeature">tableOfContents</meta>
                  <meta property="schema:accessibilityFeature">readingOrder</meta>
                  <meta property="schema:accessibilityFeature">ARIA</meta>
                  <meta property="schema:accessibilityFeature">pageBreakMarkers</meta>
                  <meta property="schema:accessibilityFeature">pageNavigation</meta>
                  <meta property="schema:accessibilityFeature">alternativeText</meta>
                  <meta property="schema:accessibilityFeature">printPageNumbers</meta>
                  <meta property="schema:accessibilityFeature">index</meta>
                  <meta property="schema:accessibilityFeature">structuralNavigation</meta>
                  <meta property="schema:accessibilityFeature">displayTransformability</meta>
                  <meta property="schema:accessibilityHazard">flashing</meta>
                  <meta property="schema:accessibilityHazard">motionSimulation</meta>
                  <meta property="schema:accessibilitySummary">A very complex book with 15 images, 10 tables, and complex formatting...</meta>
                  <meta property="dcterms:conformsTo">EPUB Accessibility 1.1 - WCAG 2.1 Level AA</meta>
                  <meta property="a11y:certifiedBy">A11yCo</meta>
                  <meta property="a11y:certifierCredential">https://a11yfoo.org/certification</meta>
                  <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                  <meta property="schema:accessModeSufficient">textual,visual</meta>
                </metadata>
              </package>
            XML
          end

          it 'indexes all expected fields' do
            described_class.index(epub.id, epub_solr_doc)
            expect(epub_solr_doc).to eq(all_a11y_metadata_doc_sans_epub_version.merge({ "epub_version_ssi" => "3.0" }))
          end
        end

        describe 'dcterms:conformsTo' do
          context 'EPUB Accessibility 1.0 specification' do
            let(:epub_content_file) do
              <<~XML
                <package version="3.0">
                  <metadata>
                    <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                    <link rel="dcterms:conformsTo" href="http://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aa"/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes the value into "epub_a11y_conforms_to_ssi"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_conforms_to_ssi']).to eq('http://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aa')
            end
          end

          context 'EPUB Accessibility 1.1 specification' do
            let(:epub_content_file) do
              <<~XML
                <package version="3.0">
                  <metadata>
                    <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                    <meta property="dcterms:conformsTo">EPUB Accessibility 1.1 - WCAG 2.0 Level AA</meta>
                  </metadata>
                </package>
              XML
            end

            it 'indexes the value into "epub_a11y_conforms_to_ssi"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_conforms_to_ssi']).to eq('EPUB Accessibility 1.1 - WCAG 2.0 Level AA')
            end
          end
        end

        describe 'screen reader friendly' do
          context 'no accessibility metadata present (i.e. no accessModeSufficient field to work from)' do
            let(:epub_content_file) do
              <<~XML
                <package version="3.0">
                  <metadata>
                    <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "unknown"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('unknown')
            end
          end

          context 'accessModeSufficient is present but no value of "textual" by itself exists' do
            let(:epub_content_file) do
              <<~XML
                <package version="3.0">
                  <metadata>
                    <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                    <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                    <meta property="schema:accessModeSufficient">textual,visual</meta>
                    <meta property="schema:accessModeSufficient">visual</meta>
                    <meta property="schema:accessModeSufficient">textual,visual</meta>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "false"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('no')
            end
          end

          context 'accessModeSufficient is present, and a value of "textual" by itself does exist' do
            let(:epub_content_file) do
              <<~XML
                <package version="3.0">
                  <metadata>
                    <meta property="nonAccessibilityThing">I am here to act as a non-a11y entry.</meta>
                    <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                    <meta property="schema:accessModeSufficient">textual,visual</meta>
                    <meta property="schema:accessModeSufficient">textual</meta>
                    <meta property="schema:accessModeSufficient">textual,visual</meta>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "false"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('yes')
            end
          end
        end
      end

      context 'EPUB 2.0 content file' do
        context 'no a11y metadata present' do
          let(:epub_content_file) do
            <<~XML
              <package version="2.0">
                <metadata>
                  <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                </metadata>
              </package>
            XML
          end

          it 'only indexes epub_version_ssi and the derived epub_a11y_screen_reader_friendly_ssi field' do
            described_class.index(epub.id, epub_solr_doc)
            expect(epub_solr_doc).to eq(missing_a11y_metadata_doc_sans_epub_version.merge({ "epub_version_ssi" => "2.0" }))
          end
        end

        context 'all a11y metadata present' do
          let(:epub_content_file) do
            <<~XML
              <package version="2.0">
                <metadata>
                  <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                  <meta name="schema:accessMode" content="textual"/>
                  <meta name="schema:accessMode" content="visual"/>
                  <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                  <meta name="schema:accessModeSufficient" content="textual,visual"/>
                  <meta name="schema:accessModeSufficient" content="textual"/>
                  <meta name="schema:accessibilityFeature" content="tableOfContents"/>
                  <meta name="schema:accessibilityFeature" content="readingOrder"/>
                  <meta name="schema:accessibilityFeature" content="ARIA"/>
                  <meta name="schema:accessibilityFeature" content="pageBreakMarkers"/>
                  <meta name="schema:accessibilityFeature" content="pageNavigation"/>
                  <meta name="schema:accessibilityFeature" content="alternativeText"/>
                  <meta name="schema:accessibilityFeature" content="printPageNumbers"/>
                  <meta name="schema:accessibilityFeature" content="index"/>
                  <meta name="schema:accessibilityFeature" content="structuralNavigation"/>
                  <meta name="schema:accessibilityFeature" content="displayTransformability"/>"
                  <meta name="schema:accessibilityHazard" content="flashing"/>
                  <meta name="schema:accessibilityHazard" content="motionSimulation"/>
                  <meta name="schema:accessibilitySummary" content="A very complex book with 15 images, 10 tables, and complex formatting..."/>
                  <meta name="dcterms:conformsTo" content="EPUB Accessibility 1.1 - WCAG 2.1 Level AA"/>
                  <meta name="a11y:certifiedBy" content="A11yCo"/>
                  <meta name="a11y:certifierCredential" content="https://a11yfoo.org/certification"/>
                  <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                  <meta name="schema:accessModeSufficient" content="textual,visual"/>
                </metadata>
              </package>
            XML
          end

          it 'indexes all expected fields' do
            described_class.index(epub.id, epub_solr_doc)
            expect(epub_solr_doc).to eq(all_a11y_metadata_doc_sans_epub_version.merge({ "epub_version_ssi" => "2.0" }))
          end
        end

        describe 'dcterms:conformsTo' do
          context 'EPUB Accessibility 1.0 specification' do
            let(:epub_content_file) do
              <<~XML
                <package version="2.0">
                  <metadata>
                    <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                    <link rel="dcterms:conformsTo" href="http://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aa"/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes the value into "epub_a11y_conforms_to_ssi"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_conforms_to_ssi']).to eq('http://www.idpf.org/epub/a11y/accessibility-20170105.html#wcag-aa')
            end
          end

          context 'EPUB Accessibility 1.1 specification' do
            let(:epub_content_file) do
              <<~XML
                <package version="2.0">
                  <metadata>
                    <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                    <meta name="dcterms:conformsTo" content="EPUB Accessibility 1.1 - WCAG 2.0 Level AA"/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes the value into "epub_a11y_conforms_to_ssi"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_conforms_to_ssi']).to eq('EPUB Accessibility 1.1 - WCAG 2.0 Level AA')
            end
          end
        end

        describe 'screen reader friendly' do
          context 'no accessibility metadata present (i.e. no accessModeSufficient field to work from)' do
            let(:epub_content_file) do
              <<~XML
                <package version="2.0">
                  <metadata>
                    <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "unknown"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('unknown')
            end
          end

          context 'accessModeSufficient is present but no value of "textual" by itself exists' do
            let(:epub_content_file) do
              <<~XML
                <package version="2.0">
                  <metadata>
                    <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                      <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                    <meta name="schema:accessModeSufficient" content="textual,visual"/>
                    <meta name="schema:accessModeSufficient" content="visual"/>
                    <meta name="schema:accessModeSufficient" content="textual,visual"/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "false"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('no')
            end
          end

          context 'accessModeSufficient is present, and a value of "textual" by itself does exist' do
            let(:epub_content_file) do
              <<~XML
                <package version="2.0">
                  <metadata>
                    <meta name="nonAccessibilityThing" content="I am here to act as a non-a11y entry."/>
                      <!-- multiple entries for accessModeSufficient are common, as are dupes and we're going to index them as they are -->
                    <meta name="schema:accessModeSufficient" content="textual,visual"/>
                    <meta name="schema:accessModeSufficient" content="textual"/>
                    <meta name="schema:accessModeSufficient" content="textual,visual"/>
                  </metadata>
                </package>
              XML
            end

            it 'indexes "false"' do
              described_class.index(epub.id, epub_solr_doc)
              expect(epub_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('yes')
            end
          end
        end
      end
    end
  end
end
