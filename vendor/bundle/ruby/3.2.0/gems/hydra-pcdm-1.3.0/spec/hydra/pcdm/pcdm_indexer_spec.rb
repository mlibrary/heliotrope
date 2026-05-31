require 'spec_helper'

describe Hydra::PCDM::PCDMIndexer do
  let(:collection) { Hydra::PCDM::Collection.new }
  let(:member_ids) { %w[123 456 789] }
  let(:indexer) { described_class.new(collection) }
  let(:collection1)   { Hydra::PCDM::Collection.new(id: 'abc') }
  let(:collection2)   { Hydra::PCDM::Collection.new(id: 'def') }

  before do
    allow(collection).to receive(:member_ids).and_return(member_ids)
    allow(collection).to receive(:member_of_collection_ids).and_return([collection1.id, collection2.id])
  end

  describe '#generate_solr_document' do
    subject { indexer.generate_solr_document }

    it 'has fields' do
      expect(subject[Hydra::PCDM::Config.indexing_member_ids_key]).to eq %w[123 456 789]
      expect(subject[Hydra::PCDM::Config.indexing_member_of_collection_ids_key]).to eq %w[abc def]
    end
  end
end
