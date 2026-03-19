# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessibilityMetadataIndexer::Pdf do
  let(:pdf) { create(:public_file_set) }
  let(:pdf_solr_doc) { {} }

  describe "Indexing PDF accessibility metadata" do
    it 'sets screen_reader_friendly to unknown' do
      described_class.new(pdf.id, pdf_solr_doc).index_reader_ebook_accessibility_metadata
      expect(pdf_solr_doc['epub_a11y_screen_reader_friendly_ssi']).to eq('unknown')
    end

    it 'does not raise any errors' do
      expect {
        described_class.new(pdf.id, pdf_solr_doc).index_reader_ebook_accessibility_metadata
      }.not_to raise_error
    end
  end
end
