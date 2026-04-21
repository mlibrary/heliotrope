# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Opds::Publication, type: [:model, :json_schema] do
  let(:publication) { described_class.new_from_monograph(monograph) }
  let(:monograph) { instance_double(Sighrax::Monograph, 'monograph') }

  describe '#to_h' do
    subject { publication.to_h }

    context 'valid' do
      let(:cover) { instance_double(Sighrax::Resource, 'cover', noid: 'covernoid') }
      let(:epub) { instance_double(Sighrax::EpubEbook, 'epub', noid: 'epub_noid') }
      let(:pdf) { instance_double(Sighrax::PdfEbook, 'pdf', noid: 'epdf_noid') }
      let(:time_now) { Time.new(2021) }

      before do
        allow(monograph).to receive(:cover).and_return(cover)
        allow(cover).to receive(:valid?).and_return(true)

        allow(monograph).to receive(:noid).and_return('validnoid')
        allow(monograph).to receive(:title).and_return('Title')

        allow(monograph).to receive(:citable_link).and_return('http://citable.link.org')
        allow(monograph).to receive(:contributors).and_return([])
        allow(monograph).to receive(:description).and_return(nil)
        allow(monograph).to receive(:identifier).and_return(nil)
        allow(monograph).to receive(:preferred_isbn).and_return(nil)
        allow(monograph).to receive(:non_preferred_isbns).and_return([])
        allow(monograph).to receive(:languages).and_return(nil)
        allow(monograph).to receive(:open_access?).and_return(true)
        allow(monograph).to receive(:modified).and_return(nil)
        allow(monograph).to receive(:publication_year).and_return(nil)
        allow(monograph).to receive(:published).and_return(nil)
        allow(monograph).to receive(:publishing_house).and_return(nil)
        allow(monograph).to receive(:series).and_return(nil)
        allow(monograph).to receive(:subjects).and_return([])

        # Default accessibility metadata mocks (can be overridden in specific tests)
        allow(monograph).to receive(:epub_a11y_accessibility_summary).and_return(nil)
        allow(monograph).to receive(:epub_a11y_conforms_to).and_return(nil)
        allow(monograph).to receive(:epub_a11y_accessibility_features).and_return([])
        allow(monograph).to receive(:epub_a11y_accessibility_hazards).and_return([])
        allow(monograph).to receive(:epub_a11y_access_modes).and_return([])
        allow(monograph).to receive(:epub_a11y_access_modes_sufficient).and_return([])
        allow(monograph).to receive(:pdf_a11y_accessibility_summary).and_return(nil)
        allow(monograph).to receive(:pdf_a11y_conforms_to).and_return(nil)
        allow(monograph).to receive(:pdf_a11y_accessibility_features).and_return([])
        allow(monograph).to receive(:pdf_a11y_accessibility_hazards).and_return([])
        allow(monograph).to receive(:pdf_a11y_access_modes).and_return([])
        allow(monograph).to receive(:pdf_a11y_access_modes_sufficient).and_return([])

        allow(Time).to receive(:now).and_return(time_now)
      end

      context 'epub and pdf' do
        before do
          allow(monograph).to receive(:epub_ebook).and_return(epub)
          allow(monograph).to receive(:pdf_ebook).and_return(pdf)
          allow(epub).to receive(:valid?).and_return(true)
          allow(pdf).to receive(:valid?).and_return(true)
        end

        it { expect(subject.keys.count).to eq(3) }
        it { expect(subject).to include(:metadata) }
        it { expect(subject).to include(:links) }
        it { expect(subject).to include(:images) }

        # Metadata (required keys + description citable link + layout + readingProgression)
        it { expect(subject[:metadata]).to include(:@type, :title, :language, :modified, :description) }
        it { expect(subject[:metadata]).to include("@type": 'http://schema.org/EBook') }
        it { expect(subject[:metadata]).to include(title: 'Title') }
        it { expect(subject[:metadata]).to include(language: 'eng') }
        it { expect(subject[:metadata]).to include(modified: time_now.utc.iso8601) }
        it { expect(subject[:metadata]).to include(description: '<div><br><a href="http://citable.link.org">View on Fulcrum platform.</a></div>') }
        it { expect(subject[:metadata]).not_to have_key(:sortAs) } # optional

        # Links
        it { expect(subject[:links].count).to eq(3) }
        it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }

        # Images
        it { expect(subject[:images].count).to eq(4) }
        it { expect(subject[:images]).to include({ href: "#{Riiif::Engine.routes.url_helpers.image_url(monograph.cover.noid, host: Rails.application.routes.url_helpers.root_url, size: 'full', format: 'jpg')}", type: 'image/jpeg' }) }
        [200, 400, 800].each do |width_size|
          it { expect(subject[:images]).to include({ href: "#{Riiif::Engine.routes.url_helpers.image_url(monograph.cover.noid, host: Rails.application.routes.url_helpers.root_url, size: "#{width_size},", format: 'jpg')}", width: width_size, type: 'image/jpeg' }) }
        end

        it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
      end

      context 'only epub' do
        before do
          allow(monograph).to receive(:epub_ebook).and_return(epub)
          allow(monograph).to receive(:pdf_ebook).and_return(Sighrax::Entity.null_entity)
          allow(epub).to receive(:valid?).and_return(true)
        end

        it { expect(subject[:links].count).to eq(2) }
        it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }

        # EPUB should include layout and readingProgression
        it { expect(subject[:metadata]).to include(layout: 'reflowable') }
        it { expect(subject[:metadata]).to include(readingProgression: 'ltr') }

        it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
      end

      context 'only pdf' do
        before do
          allow(monograph).to receive(:epub_ebook).and_return(Sighrax::Entity.null_entity)
          allow(monograph).to receive(:pdf_ebook).and_return(pdf)
          allow(pdf).to receive(:valid?).and_return(true)
        end

        it { expect(subject[:links].count).to eq(2) }
        it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
        it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }

        # PDF-only should not include layout or readingProgression
        it { expect(subject[:metadata]).not_to have_key(:layout) }
        it { expect(subject[:metadata]).not_to have_key(:readingProgression) }

        it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
      end

      context 'restricted access' do
        before do
          allow(monograph).to receive(:open_access?).and_return(false)
        end

        context 'epub and pdf' do
          before do
            allow(monograph).to receive(:epub_ebook).and_return(epub)
            allow(monograph).to receive(:pdf_ebook).and_return(pdf)
            allow(epub).to receive(:valid?).and_return(true)
            allow(pdf).to receive(:valid?).and_return(true)
          end

          it { expect(subject[:links].count).to eq(3) }
          it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
          it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
          it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
          it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
          it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
        end

        context 'only epub' do
          before do
            allow(monograph).to receive(:epub_ebook).and_return(epub)
            allow(monograph).to receive(:pdf_ebook).and_return(Sighrax::Entity.null_entity)
            allow(epub).to receive(:valid?).and_return(true)
          end

          it { expect(subject[:links].count).to eq(2) }
          it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
          it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
          it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(epub.noid), type: 'application/epub+zip' }) }
        end

        context 'only pdf' do
          before do
            allow(monograph).to receive(:epub_ebook).and_return(Sighrax::Entity.null_entity)
            allow(monograph).to receive(:pdf_ebook).and_return(pdf)
            allow(pdf).to receive(:valid?).and_return(true)
          end

          it { expect(subject[:links].count).to eq(2) }
          it { expect(subject[:links]).to include({ rel: 'self', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
          it { expect(subject[:links]).to include({ rel: 'http://opds-spec.org/acquisition', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
          it { expect(subject[:links]).not_to include({ rel: 'http://opds-spec.org/acquisition/open-access', href: Rails.application.routes.url_helpers.download_ebook_url(pdf.noid), type: 'application/pdf' }) }
        end
      end

      context 'metadata' do
        before do
          allow(monograph).to receive(:epub_ebook).and_return(epub)
          allow(monograph).to receive(:pdf_ebook).and_return(pdf)
          allow(epub).to receive(:valid?).and_return(true)
          allow(pdf).to receive(:valid?).and_return(true)
        end

        describe 'contributor' do
          before do
            allow(monograph).to receive(:contributors).and_return(
              [
                  'Artist (artist)',
                  'Author',
                  'Colorist (colorist)',
                  'Editor (editor)',
                  'Illustrator (illustrator)',
                  'Inker (inker)',
                  'Letterer (letterer)',
                  'Narrator (narrator)',
                  'Penciler (penciler)',
                  'Translator (translator)',
                  'Other (other)'
              ]
            )
          end

          it { expect(subject[:metadata].keys.count).to eq(9) }
          it { expect(subject[:metadata]).to include(author: 'Author') }
          it { expect(subject[:metadata]).to include(editor: 'Editor') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }

          context 'when multiple authors and editors' do
            before do
              allow(monograph).to receive(:contributors).and_return(
                [
                  'Author1',
                  'Author2',
                  'Editor1 (editor)',
                  'Editor2 (editor)'
                ]
              )
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata][:author]).to contain_exactly('Author1', 'Author2') }
            it { expect(subject[:metadata][:editor]).to contain_exactly('Editor1', 'Editor2') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        context 'belongsTo' do
          describe '#collection' do
            # before { allow(monograph).to receive(:collection).and_return('Collection') }

            it { expect(subject[:metadata].keys.count).to eq(7) }
            it { expect(subject[:metadata]).not_to have_key(:belongsTo) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          describe '#series' do
            before { allow(monograph).to receive(:series).and_return('Series') }

            it { expect(subject[:metadata].keys.count).to eq(8) }
            it { expect(subject[:metadata]).to include(belongsTo: { series: 'Series' }) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#description' do
          before { allow(monograph).to receive(:description).and_return('Description') }

          it { expect(subject[:metadata].keys.count).to eq(7) }
          it { expect(subject[:metadata]).to include(description: '<div>Description<br><a href="http://citable.link.org">View on Fulcrum platform.</a></div>') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#identifier' do
          context 'when monograph has preferred ISBN' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:identifier).and_return('https://doi.org/10.3998/mpub.9853855')
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata]).to include(identifier: 'urn:isbn:9780472074501') }
            it { expect(subject[:metadata]).to include(altIdentifier: ['urn:doi:10.3998/mpub.9853855']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when monograph has no ISBN' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return(nil)
              allow(monograph).to receive(:identifier).and_return('https://doi.org/10.3998/mpub.9853855')
            end

            it { expect(subject[:metadata].keys.count).to eq(8) }
            it { expect(subject[:metadata]).to include(identifier: 'https://doi.org/10.3998/mpub.9853855') }
            it { expect(subject[:metadata]).not_to have_key(:altIdentifier) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#altIdentifier' do
          context 'when monograph has non-preferred ISBNs and DOI' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:non_preferred_isbns).and_return(['9780472901289', '9780472054503'])
              allow(monograph).to receive(:identifier).and_return('https://doi.org/10.3998/mpub.9853855')
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata]).to include(altIdentifier: ['urn:isbn:9780472901289', 'urn:isbn:9780472054503', 'urn:doi:10.3998/mpub.9853855']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when monograph has non-preferred ISBNs and handle' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:non_preferred_isbns).and_return(['9780472901289'])
              allow(monograph).to receive(:identifier).and_return('https://hdl.handle.net/2027/fulcrum.0g354f20t')
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata]).to include(altIdentifier: ['urn:isbn:9780472901289', 'https://hdl.handle.net/2027/fulcrum.0g354f20t']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when monograph has only non-preferred ISBNs' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:non_preferred_isbns).and_return(['9780472901289', '9780472054503'])
              allow(monograph).to receive(:identifier).and_return(nil)
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata]).to include(altIdentifier: ['urn:isbn:9780472901289', 'urn:isbn:9780472054503']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when monograph has only DOI' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:non_preferred_isbns).and_return([])
              allow(monograph).to receive(:identifier).and_return('https://doi.org/10.3998/mpub.9853855')
            end

            it { expect(subject[:metadata].keys.count).to eq(9) }
            it { expect(subject[:metadata]).to include(altIdentifier: ['urn:doi:10.3998/mpub.9853855']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when monograph has neither non-preferred ISBNs nor DOI/handle' do
            before do
              allow(monograph).to receive(:preferred_isbn).and_return('9780472074501')
              allow(monograph).to receive(:non_preferred_isbns).and_return([])
              allow(monograph).to receive(:identifier).and_return(nil)
            end

            it { expect(subject[:metadata].keys.count).to eq(8) }
            it { expect(subject[:metadata]).not_to have_key(:altIdentifier) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#language' do
          let(:languages) { %w[language] }

          before { allow(monograph).to receive(:languages).and_return(languages) }

          it { expect(subject[:metadata].keys.count).to eq(7) }
          it { expect(subject[:metadata]).to include(language: 'eng') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }

          context 'multiple languages' do
            let(:languages) { %w[en eng english fr frc french espanol] }

            it { expect(subject[:metadata].keys.count).to eq(7) }
            it { expect(subject[:metadata][:language]).to contain_exactly('eng', 'frc', 'spa') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#modified' do
          context 'when published' do
            before { allow(monograph).to receive(:published).and_return(date_published) }

            let(:date_published) { 1.year.ago }

            it { expect(subject[:metadata].keys.count).to eq(7) }
            it { expect(subject[:metadata]).to include(modified: date_published.iso8601) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }

            context 'when published and modified' do
              before { allow(monograph).to receive(:modified).and_return(date_modified) }

              let(:date_modified) { 6.months.ago }

              it { expect(subject[:metadata].keys.count).to eq(7) }
              it { expect(subject[:metadata]).to include(modified: date_modified.iso8601) }
              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end
          end
        end

        describe '#published' do
          let(:year) { 1969 }
          let(:date) { Date.parse("#{year}-01-01") }

          before { allow(monograph).to receive(:publication_year).and_return(year) }

          it { expect(subject[:metadata].keys.count).to eq(8) }
          it { expect(subject[:metadata]).to include(published: date.iso8601) }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#publisher' do
          before { allow(monograph).to receive(:publishing_house).and_return('Publishing House') }

          it { expect(subject[:metadata].keys.count).to eq(8) }
          it { expect(subject[:metadata]).to include(publisher: 'Publishing House') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#subject' do
          context 'singular' do
            before { allow(monograph).to receive(:subjects).and_return(['Subject']) }

            it { expect(subject[:metadata].keys.count).to eq(8) }
            it { expect(subject[:metadata]).to include(subject: 'Subject') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'plural' do
            before { allow(monograph).to receive(:subjects).and_return(['Subject A', 'Subject B']) }

            it { expect(subject[:metadata].keys.count).to eq(8) }
            it { expect(subject[:metadata]).to include(subject: ['Subject A', 'Subject B']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#layout' do
          it 'includes layout for EPUB' do
            expect(subject[:metadata].keys.count).to eq(7)
            expect(subject[:metadata]).to include(layout: 'reflowable')
          end

          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#readingProgression' do
          it 'includes readingProgression for EPUB' do
            expect(subject[:metadata].keys.count).to eq(7)
            expect(subject[:metadata]).to include(readingProgression: 'ltr')
          end

          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        [:abridged, :duration, :imprint, :numberOfPages, :subtitle].each do |method|
          describe "##{method}" do
            it { expect(subject[:metadata].keys.count).to eq(7) }
            it { expect(subject[:metadata]).not_to have_key(method) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe 'accessibility metadata' do
          context 'when epub has accessibility metadata' do
            before do
              # Mock the monograph to respond with accessibility metadata
              allow(monograph).to receive(:epub_a11y_accessibility_summary)
                                               .and_return('Includes captions and structured navigation.')
              allow(monograph).to receive(:epub_a11y_conforms_to)
                                               .and_return('https://www.w3.org/TR/epub-a11y-11/#wcag-aa')
              allow(monograph).to receive(:epub_a11y_accessibility_features)
                                               .and_return(['alternativeText', 'tableOfContents', 'structuralNavigation'])
              allow(monograph).to receive(:epub_a11y_accessibility_hazards)
                                               .and_return(['none'])
              allow(monograph).to receive(:epub_a11y_access_modes)
                                               .and_return(['textual', 'visual'])
              allow(monograph).to receive(:epub_a11y_access_modes_sufficient)
                                               .and_return(['textual,visual', 'textual'])
            end

            it 'includes accessibility metadata in the output' do
              expect(subject[:metadata]).to have_key(:accessibility)
              expect(subject[:metadata][:accessibility]).to include(summary: 'Includes captions and structured navigation.')
              expect(subject[:metadata][:accessibility]).to include(conformsTo: ['https://www.w3.org/TR/epub-a11y-11/#wcag-aa'])
              expect(subject[:metadata][:accessibility]).to include(feature: ['alternativeText', 'tableOfContents', 'structuralNavigation'])
              expect(subject[:metadata][:accessibility]).to include(hazard: ['none'])
              expect(subject[:metadata][:accessibility]).to include(accessMode: ['textual', 'visual'])
              expect(subject[:metadata][:accessibility]).to include(accessModeSufficient: [['textual', 'visual'], 'textual'])
            end

            it 'counts accessibility metadata fields correctly' do
              # 5 base fields + 2 epub fields (layout, readingProgression) + 1 accessibility object = 8
              expect(subject[:metadata].keys.count).to eq(8)
              expect(subject[:metadata][:accessibility].keys.count).to eq(6)
            end

            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when epub has partial accessibility metadata' do
            before do
              allow(monograph).to receive(:epub_a11y_accessibility_summary)
                                               .and_return('Some summary text')
              allow(monograph).to receive(:epub_a11y_conforms_to)
                                               .and_return(nil)
              allow(monograph).to receive(:epub_a11y_accessibility_features)
                                               .and_return(['readingOrder'])
              allow(monograph).to receive(:epub_a11y_accessibility_hazards)
                                               .and_return([])
              allow(monograph).to receive(:epub_a11y_access_modes)
                                               .and_return([])
              allow(monograph).to receive(:epub_a11y_access_modes_sufficient)
                                               .and_return([])
            end

            it 'includes only non-blank accessibility metadata' do
              expect(subject[:metadata]).to have_key(:accessibility)
              expect(subject[:metadata][:accessibility]).to include(summary: 'Some summary text')
              expect(subject[:metadata][:accessibility]).to include(feature: ['readingOrder'])
              expect(subject[:metadata][:accessibility]).not_to have_key(:conformsTo)
              expect(subject[:metadata][:accessibility]).not_to have_key(:hazard)
              expect(subject[:metadata][:accessibility]).not_to have_key(:accessMode)
              expect(subject[:metadata][:accessibility]).not_to have_key(:accessModeSufficient)
            end

            it 'counts only present fields' do
              # 5 base fields + 2 epub fields (layout, readingProgression) + 1 accessibility object = 8
              expect(subject[:metadata].keys.count).to eq(8)
              expect(subject[:metadata][:accessibility].keys.count).to eq(2)
            end

            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'when epub has no accessibility metadata' do
            before do
              allow(monograph).to receive(:epub_a11y_accessibility_summary)
                                               .and_return(nil)
              allow(monograph).to receive(:epub_a11y_conforms_to)
                                               .and_return(nil)
              allow(monograph).to receive(:epub_a11y_accessibility_features)
                                               .and_return([])
              allow(monograph).to receive(:epub_a11y_accessibility_hazards)
                                               .and_return([])
              allow(monograph).to receive(:epub_a11y_access_modes)
                                               .and_return([])
              allow(monograph).to receive(:epub_a11y_access_modes_sufficient)
                                               .and_return([])
            end

            it 'does not include accessibility metadata keys' do
              expect(subject[:metadata]).not_to have_key(:accessibility)
            end

            it 'only has base metadata fields' do
              # 5 base fields + 2 epub fields = 7
              expect(subject[:metadata].keys.count).to eq(7)
            end

            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe 'accessibility metadata when PDF is available' do
          before do
            allow(monograph).to receive(:pdf_ebook).and_return(pdf)
            allow(pdf).to receive(:valid?).and_return(true)
          end

          describe 'EPUB and PDF both present' do
            before do
              allow(monograph).to receive(:epub_ebook).and_return(epub)
              allow(epub).to receive(:valid?).and_return(true)
            end

            context 'when EPUB has accessibility metadata' do
              before do
                allow(monograph).to receive(:epub_a11y_accessibility_summary).and_return('EPUB summary')
                allow(monograph).to receive(:pdf_a11y_accessibility_summary)
                                                 .and_return('This PDF summary should not appear')
                allow(monograph).to receive(:pdf_a11y_accessibility_features)
                                                 .and_return(['taggedPDF'])
              end

              it 'uses EPUB accessibility metadata and not PDF accessibility metadata' do
                expect(subject[:metadata]).to have_key(:accessibility)
                expect(subject[:metadata][:accessibility]).to include(summary: 'EPUB summary')
                expect(subject[:metadata][:accessibility]).not_to include(summary: 'This PDF summary should not appear')
              end

              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end

            context 'when EPUB has no accessibility metadata' do
              before do
                allow(monograph).to receive(:pdf_a11y_accessibility_summary)
                                                 .and_return('This PDF summary should appear')
                allow(monograph).to receive(:pdf_a11y_accessibility_features)
                                                 .and_return(['taggedPDF'])
              end

              it 'falls back to PDF accessibility metadata' do
                expect(subject[:metadata]).to have_key(:accessibility)
                expect(subject[:metadata][:accessibility]).to include(summary: 'This PDF summary should appear')
                expect(subject[:metadata][:accessibility]).to include(feature: ['taggedPDF'])
              end

              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end
          end

          describe 'PDF-only (no EPUB)' do
            before do
              allow(monograph).to receive(:epub_ebook).and_return(Sighrax::Entity.null_entity)
            end

            context 'when PDF has no accessibility metadata' do
              it 'does not include accessibility metadata' do
                expect(subject[:metadata]).not_to have_key(:accessibility)
              end

              it 'only has base metadata fields' do
                expect(subject[:metadata].keys.count).to eq(5)
              end

              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end

            context 'when PDF has accessibility metadata' do
              before do
                allow(monograph).to receive(:pdf_a11y_accessibility_summary)
                                                 .and_return('This PDF meets accessibility standards.')
                allow(monograph).to receive(:pdf_a11y_conforms_to)
                                                 .and_return('https://www.w3.org/TR/epub-a11y-11/#wcag-aa')
                allow(monograph).to receive(:pdf_a11y_accessibility_features)
                                                 .and_return(['taggedPDF', 'readingOrder'])
                allow(monograph).to receive(:pdf_a11y_accessibility_hazards)
                                                 .and_return(['none'])
                allow(monograph).to receive(:pdf_a11y_access_modes)
                                                 .and_return(['textual', 'visual'])
                allow(monograph).to receive(:pdf_a11y_access_modes_sufficient)
                                                 .and_return(['textual,visual', 'textual'])
              end

              it 'includes accessibility metadata in the output' do
                expect(subject[:metadata]).to have_key(:accessibility)
                expect(subject[:metadata][:accessibility]).to include(summary: 'This PDF meets accessibility standards.')
                expect(subject[:metadata][:accessibility]).to include(conformsTo: ['https://www.w3.org/TR/epub-a11y-11/#wcag-aa'])
                expect(subject[:metadata][:accessibility]).to include(feature: ['taggedPDF', 'readingOrder'])
                expect(subject[:metadata][:accessibility]).to include(hazard: ['none'])
                expect(subject[:metadata][:accessibility]).to include(accessMode: ['textual', 'visual'])
                expect(subject[:metadata][:accessibility]).to include(accessModeSufficient: [['textual', 'visual'], 'textual'])
              end

              it 'counts accessibility metadata fields correctly' do
                # 5 base fields + 1 accessibility object = 6
                expect(subject[:metadata].keys.count).to eq(6)
                expect(subject[:metadata][:accessibility].keys.count).to eq(6)
              end

              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end
          end
        end
      end
    end
  end
end
