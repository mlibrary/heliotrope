require 'spec_helper'

describe Hydra::PCDM::Config do
  context '.indexing_member_ids_key' do
    subject { described_class.indexing_member_ids_key }
    it { is_expected.to eq(described_class::INDEXING_MEMBER_IDS_KEY) }
  end

  context '.indexing_collection_ids_key' do
    subject { described_class.indexing_collection_ids_key }
    it { is_expected.to eq(described_class::INDEXING_COLLECTION_IDS_KEY) }
  end

  context '.indexing_object_ids_key' do
    subject { described_class.indexing_object_ids_key }
    it { is_expected.to eq(described_class::INDEXING_OBJECT_IDS_KEY) }
  end
end
