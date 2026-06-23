# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessibilityMetadataIndexer::Pdf do
  let(:file_set_id) { 'validnoid1' }
  let(:solr_doc) { {} }
  let(:press) { 'testpress' }
  let(:pdf_checksum) { 'native_tagged_bookmarks' }

  # Settings.pdf_ebook_accessibility_metadata.dir is configured in config/settings/test.yml
  # to point at spec/fixtures/accessibility_metadata_indexer/, so most tests need no Settings stub.
  before do
    allow(ActiveFedora::SolrService).to receive(:query).and_return(
      [{ 'original_checksum_ssim' => [pdf_checksum] }]
    )
  end

  def index!
    described_class.new(file_set_id, solr_doc, press).index_reader_ebook_accessibility_metadata
  end

  describe '#index_reader_ebook_accessibility_metadata' do
    context 'when Settings.pdf_ebook_accessibility_metadata is not configured' do
      before { allow(Settings).to receive(:pdf_ebook_accessibility_metadata).and_return(nil) }
      it 'indexes nothing and does not raise' do
        expect { index! }.not_to raise_error
        expect(solr_doc).to be_empty
      end
    end

    context 'when the press directory does not exist' do
      let(:press) { 'nonexistent_press' }

      it 'indexes nothing and does not raise' do
        expect { index! }.not_to raise_error
        expect(solr_doc).to be_empty
      end
    end

    context 'when no matching JSON file exists for the PDF checksum' do
      let(:pdf_checksum) { 'no_such_checksum' }

      it 'indexes nothing and does not raise' do
        expect { index! }.not_to raise_error
        expect(solr_doc).to be_empty
      end
    end

    context 'with a native PDF (tagged, has bookmarks, all conformance checks fail)' do
      # Drawn from a real ummaa PDF; title, creator and ISBN obfuscated.
      # Fixture: spec/fixtures/accessibility_metadata_indexer/testpress/native_tagged_bookmarks.json
      let(:pdf_checksum) { 'native_tagged_bookmarks' }

      it 'indexes the document type' do
        index!
        expect(solr_doc['pdf_a11y_document_type_ssi']).to eq 'native'
      end

      it 'indexes machine-readable text (embedded), tagged structure, and bookmarks as accessibility features' do
        index!
        expect(solr_doc['pdf_a11y_accessibility_feature_ssim']).to eq [
          'Bookmarks',
          'Machine-readable text (Embedded)',
          'Tagged structure'
        ]
      end

      it 'indexes access_mode as textual and visual' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_ssim']).to eq ['textual', 'visual']
      end

      it 'indexes access_mode_sufficient as textual' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_sufficient_ssim']).to eq ['textual']
      end

      it 'does not index a conforms_to value when no conformance checks pass' do
        index!
        expect(solr_doc['pdf_a11y_conforms_to_ssi']).to be_nil
      end

      it 'sets screen_reader_friendly to "no, but includes some accessibility features" (3 of 5 features, no conformance)' do
        index!
        expect(solr_doc['pdf_a11y_screen_reader_friendly_ssi']).to eq 'no, but includes some accessibility features'
      end
    end

    context 'with a scanned OCR PDF (tagged, has bookmarks, passes PDF/UA-1 and WCAG 2.2 AA)' do
      # Drawn from a real heb PDF; title, creator and ISBN obfuscated.
      # Fixture: spec/fixtures/accessibility_metadata_indexer/testpress/scanned_ocr_pdfua_pass.json
      let(:pdf_checksum) { 'scanned_ocr_pdfua_pass' }

      it 'indexes the document type' do
        index!
        expect(solr_doc['pdf_a11y_document_type_ssi']).to eq 'scanned_ocr'
      end

      it 'indexes machine-readable text (OCR), tagged structure, and bookmarks as accessibility features' do
        index!
        expect(solr_doc['pdf_a11y_accessibility_feature_ssim']).to eq [
          'Bookmarks',
          'Machine-readable text (OCR)',
          'Tagged structure'
        ]
      end

      it 'indexes access_mode as textual and visual' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_ssim']).to eq ['textual', 'visual']
      end

      it 'does not index access_mode_sufficient for scanned OCR' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_sufficient_ssim']).to be_nil
      end

      it 'indexes the passing conformance standards' do
        index!
        expect(solr_doc['pdf_a11y_conforms_to_ssi']).to eq 'PDF/UA-1, WCAG 2.2 AA'
      end

      it 'sets screen_reader_friendly to "yes" because PDF/UA-1 conformance passes' do
        index!
        expect(solr_doc['pdf_a11y_screen_reader_friendly_ssi']).to eq 'yes'
      end
    end

    context 'with a scanned unreadable PDF (not tagged, no bookmarks, all conformance checks fail)' do
      # Fixture: spec/fixtures/accessibility_metadata_indexer/testpress/scanned_unreadable_no_features.json
      let(:pdf_checksum) { 'scanned_unreadable_no_features' }

      it 'indexes the document type' do
        index!
        expect(solr_doc['pdf_a11y_document_type_ssi']).to eq 'scanned_unreadable'
      end

      it 'indexes accessibility_features as None' do
        index!
        expect(solr_doc['pdf_a11y_accessibility_feature_ssim']).to eq ['None']
      end

      it 'indexes access_mode as visual only' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_ssim']).to eq ['visual']
      end

      it 'does not index access_mode_sufficient' do
        index!
        expect(solr_doc['pdf_a11y_access_mode_sufficient_ssim']).to be_nil
      end

      it 'does not index a conforms_to value' do
        index!
        expect(solr_doc['pdf_a11y_conforms_to_ssi']).to be_nil
      end

      it 'sets screen_reader_friendly to "no" (no accessibility features at all)' do
        index!
        expect(solr_doc['pdf_a11y_screen_reader_friendly_ssi']).to eq 'no'
      end
    end
  end
end
