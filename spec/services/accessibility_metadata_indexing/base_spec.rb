# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessibilityMetadataIndexer::Base do
  let(:file_set_id) { 'test123' }
  let(:solr_doc) { {} }
  let(:base_instance) { described_class.new(file_set_id, solr_doc) }

  describe 'initialization' do
    it 'sets file_set_id' do
      expect(base_instance.file_set_id).to eq(file_set_id)
    end

    it 'sets solr_doc' do
      expect(base_instance.solr_doc).to eq(solr_doc)
    end
  end

  describe 'abstract methods' do
    it 'raises NotImplementedError for index_reader_ebook_accessibility_metadata' do
      expect {
        base_instance.index_reader_ebook_accessibility_metadata
      }.to raise_error(NotImplementedError, /must implement #index_reader_ebook_accessibility_metadata/)
    end

    it 'raises NotImplementedError for accessibility_summary' do
      expect {
        base_instance.send(:accessibility_summary)
      }.to raise_error(NotImplementedError, /must implement #accessibility_summary/)
    end

    it 'raises NotImplementedError for accessibility_features' do
      expect {
        base_instance.send(:accessibility_features)
      }.to raise_error(NotImplementedError, /must implement #accessibility_features/)
    end

    it 'raises NotImplementedError for accessibility_hazard' do
      expect {
        base_instance.send(:accessibility_hazard)
      }.to raise_error(NotImplementedError, /must implement #accessibility_hazard/)
    end

    it 'raises NotImplementedError for access_mode' do
      expect {
        base_instance.send(:access_mode)
      }.to raise_error(NotImplementedError, /must implement #access_mode/)
    end

    it 'raises NotImplementedError for access_mode_sufficient' do
      expect {
        base_instance.send(:access_mode_sufficient)
      }.to raise_error(NotImplementedError, /must implement #access_mode_sufficient/)
    end

    it 'raises NotImplementedError for conforms_to' do
      expect {
        base_instance.send(:conforms_to)
      }.to raise_error(NotImplementedError, /must implement #conforms_to/)
    end

    it 'raises NotImplementedError for certified_by' do
      expect {
        base_instance.send(:certified_by)
      }.to raise_error(NotImplementedError, /must implement #certified_by/)
    end

    it 'raises NotImplementedError for certifier_credential' do
      expect {
        base_instance.send(:certifier_credential)
      }.to raise_error(NotImplementedError, /must implement #certifier_credential/)
    end

    it 'raises NotImplementedError for screen_reader_friendly' do
      expect {
        base_instance.send(:screen_reader_friendly)
      }.to raise_error(NotImplementedError, /must implement #screen_reader_friendly/)
    end
  end
end
