require 'rails_helper'

describe MonographIndexer do
  let(:indexer) { described_class.new(monograph) }
  let(:monograph) { create(:monograph) }
  let(:chapter1) { create(:section) }
  let(:file) { create(:file_set) }

  before do
    monograph.ordered_members << file
    monograph.ordered_members << chapter1
    monograph.save!
  end

  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }

    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [file.id, chapter1.id]
    end
  end
end
