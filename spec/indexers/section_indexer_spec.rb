require 'rails_helper'

describe SectionIndexer do
  let(:indexer) { described_class.new(section) }
  let(:section) { create(:section) }
  let(:file1) { create(:file_set) }
  let(:file2) { create(:file_set) }

  before do
    section.ordered_members << file1
    section.ordered_members << file2
    section.save!
  end

  describe 'indexing a section' do
    subject { indexer.generate_solr_document }
    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [file1.id, file2.id]
    end
  end
end
