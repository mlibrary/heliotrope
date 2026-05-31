require 'spec_helper'

describe Blacklight::Gallery::OpenseadragonSolrDocument do
  subject { SolrDocument.new(fields).to_openseadragon(view_config) }

  context 'when configured for the view' do
    let(:fields) { { some_field: 'data' } }
    let(:view_config) { double('ViewConfig', tile_source_field: :some_field) }
    it 'returns the data from the document as an array' do
      expect(subject).to eq ['data']
    end
  end

  context 'when not configured for the view' do
    let(:fields) { { some_field: 'data' } }
    let(:view_config) { double('ViewConfig', tile_source_field: nil) }
    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'when the document has the field' do
    let(:fields) { { some_field: 'data' } }
    let(:view_config) { double('ViewConfig', tile_source_field: :some_field) }
    it 'returns the data from the document as an array' do
      expect(subject).to eq ['data']
    end
  end

  context 'when the document does not have the field' do
    let(:fields) { { some_other_field: 'data' } }
    let(:view_config) { double('ViewConfig', tile_source_field: :some_field) }
    it 'returns the data from the document as an array' do
      expect(subject).to be_nil
    end
  end
end
