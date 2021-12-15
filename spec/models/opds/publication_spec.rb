# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Opds::Publication, type: [:model, :json_schema] do
  let(:publication) { described_class.new_from_monograph(monograph) }
  let(:monograph) { instance_double(Sighrax::Monograph, 'monograph') }

  describe '#valid?' do
    subject { publication.valid? }

    it { is_expected.to be false }

    context 'valid open access monograph' do
      let(:open_access) { true }
      let(:cover) { instance_double(Sighrax::Resource, 'cover') }
      let(:epub) { instance_double(Sighrax::EpubEbook, 'epub') }
      let(:pdf) { instance_double(Sighrax::PdfEbook, 'pdf') }

      before do
        allow(monograph).to receive(:is_a?).with(Sighrax::Monograph).and_return(true)
        allow(monograph).to receive(:published?).and_return(true)
        allow(monograph).to receive(:open_access?).and_return(open_access)
        allow(monograph).to receive(:cover).and_return(cover)
        allow(monograph).to receive(:epub_ebook).and_return(epub)
        allow(monograph).to receive(:pdf_ebook).and_return(pdf)
        allow(cover).to receive(:valid?).and_return(true)
        allow(epub).to receive(:valid?).and_return(true)
        allow(pdf).to receive(:valid?).and_return(true)
      end

      it { is_expected.to be true }

      context 'when non open access' do
        let(:open_access) { false }

        it { is_expected.to be false }
      end

      context 'when open access not required' do
        let(:publication) { described_class.new_from_monograph(monograph, false) }

        it { is_expected.to be true }
      end
    end
  end

  describe '#to_h' do
    subject { publication.to_h }

    it { expect { subject }.to raise_error(StandardError, 'Invalid OPDS Publication') }

    context 'valid' do
      let(:cover) { instance_double(Sighrax::Resource, 'cover', noid: 'covernoid') }
      let(:epub) { instance_double(Sighrax::EpubEbook, 'epub', noid: 'epub_noid') }
      let(:pdf) { instance_double(Sighrax::PdfEbook, 'pdf', noid: 'epdf_noid') }
      let(:time_now) { Time.new(2021) }

      before do
        allow(publication).to receive(:valid?).and_return(true)

        allow(monograph).to receive(:cover).and_return(cover)
        allow(cover).to receive(:valid?).and_return(true)

        allow(monograph).to receive(:noid).and_return('validnoid')
        allow(monograph).to receive(:title).and_return('Title')

        allow(monograph).to receive(:citable_link).and_return('http://citable.link.org')
        allow(monograph).to receive(:contributors).and_return([])
        allow(monograph).to receive(:description).and_return(nil)
        allow(monograph).to receive(:identifier).and_return(nil)
        allow(monograph).to receive(:languages).and_return(nil)
        allow(monograph).to receive(:modified).and_return(nil)
        allow(monograph).to receive(:publication_year).and_return(nil)
        allow(monograph).to receive(:published).and_return(nil)
        allow(monograph).to receive(:publishing_house).and_return(nil)
        allow(monograph).to receive(:series).and_return(nil)
        allow(monograph).to receive(:subjects).and_return([])

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

        # Metadata (required keys + description citable link)
        it { expect(subject[:metadata].keys.count).to eq(5) }
        it { expect(subject[:metadata]).to include("@type": 'http:://schema.org/EBook') }
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

        it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
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

          it { expect(subject[:metadata].keys.count).to eq(7) }
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

            it { expect(subject[:metadata].keys.count).to eq(7) }
            it { expect(subject[:metadata][:author]).to contain_exactly('Author1', 'Author2') }
            it { expect(subject[:metadata][:editor]).to contain_exactly('Editor1', 'Editor2') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        context 'belongsTo' do
          describe '#collection' do
            # before { allow(monograph).to receive(:collection).and_return('Collection') }

            it { expect(subject[:metadata].keys.count).to eq(5) }
            it { expect(subject[:metadata]).not_to have_key(:belongsTo) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          describe '#series' do
            before { allow(monograph).to receive(:series).and_return('Series') }

            it { expect(subject[:metadata].keys.count).to eq(6) }
            it { expect(subject[:metadata]).to include(belongsTo: { series: 'Series' }) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#description' do
          before { allow(monograph).to receive(:description).and_return('Description') }

          it { expect(subject[:metadata].keys.count).to eq(5) }
          it { expect(subject[:metadata]).to include(description: '<div>Description<br><a href="http://citable.link.org">View on Fulcrum platform.</a></div>') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#identifier' do
          before { allow(monograph).to receive(:identifier).and_return('https://Identifier') }

          it { expect(subject[:metadata].keys.count).to eq(6) }
          it { expect(subject[:metadata]).to include(identifier: 'https://Identifier') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#language' do
          let(:languages) { %w[language] }

          before { allow(monograph).to receive(:languages).and_return(languages) }

          it { expect(subject[:metadata].keys.count).to eq(5) }
          it { expect(subject[:metadata]).to include(language: 'eng') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }

          context 'multiple languages' do
            let(:languages) { %w[en eng english fr frc french espanol] }

            it { expect(subject[:metadata].keys.count).to eq(5) }
            it { expect(subject[:metadata][:language]).to contain_exactly('eng', 'frc', 'spa') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        describe '#modified' do
          context 'when published' do
            before { allow(monograph).to receive(:published).and_return(date_published) }

            let(:date_published) { 1.year.ago }

            it { expect(subject[:metadata].keys.count).to eq(5) }
            it { expect(subject[:metadata]).to include(modified: date_published.iso8601) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }

            context 'when published and modified' do
              before { allow(monograph).to receive(:modified).and_return(date_modified) }

              let(:date_modified) { 6.months.ago }

              it { expect(subject[:metadata].keys.count).to eq(5) }
              it { expect(subject[:metadata]).to include(modified: date_modified.iso8601) }
              it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
            end
          end
        end

        describe '#published' do
          let(:year) { 1969 }
          let(:date) { Date.parse("#{year}-01-01") }

          before { allow(monograph).to receive(:publication_year).and_return(year) }

          it { expect(subject[:metadata].keys.count).to eq(6) }
          it { expect(subject[:metadata]).to include(published: date.iso8601) }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#publisher' do
          before { allow(monograph).to receive(:publishing_house).and_return('Publishing House') }

          it { expect(subject[:metadata].keys.count).to eq(6) }
          it { expect(subject[:metadata]).to include(publisher: 'Publishing House') }
          it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
        end

        describe '#subject' do
          context 'singular' do
            before { allow(monograph).to receive(:subjects).and_return(['Subject']) }

            it { expect(subject[:metadata].keys.count).to eq(6) }
            it { expect(subject[:metadata]).to include(subject: 'Subject') }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end

          context 'plural' do
            before { allow(monograph).to receive(:subjects).and_return(['Subject A', 'Subject B']) }

            it { expect(subject[:metadata].keys.count).to eq(6) }
            it { expect(subject[:metadata]).to include(subject: ['Subject A', 'Subject B']) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end

        [:abriged, :duration, :imprint, :numberOfPages, :readingProgression, :subtitle].each do |method|
          describe "##{method}" do
            it { expect(subject[:metadata].keys.count).to eq(5) }
            it { expect(subject[:metadata]).not_to have_key(method) }
            it { expect(schemer_validate?(opds_publication_schemer, JSON.parse(subject.to_json))).to be true }
          end
        end
      end
    end
  end
end
