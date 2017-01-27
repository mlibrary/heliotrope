require 'rails_helper'

describe MonographIndexer do
  let(:indexer) { described_class.new(monograph) }
  let(:monograph) { create(:monograph) }
  let(:section1) { create(:section) }
  let(:section2) { create(:section) }
  let(:monograph_file1) { create(:file_set) }
  let(:monograph_file2) { create(:file_set) }
  let(:section1_file1) { create(:file_set) }
  let(:section1_file2) { create(:file_set) }
  let(:section2_file1) { create(:file_set) }

  before do
    section1.ordered_members << section1_file1 << section1_file2
    section2.ordered_members << section2_file1
    monograph.ordered_members << monograph_file1
    monograph.ordered_members << section1
    monograph.ordered_members << monograph_file2
    monograph.ordered_members << section2
    monograph.save!
  end

  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }
    let(:press_name) { Press.find_by(subdomain: monograph.press).name }

    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [monograph_file1.id,
                                                        section1.id,
                                                        monograph_file2.id,
                                                        section2.id]
    end

    it 'indexes the press name' do
      expect(subject['press_name_ssim']).to eq press_name
    end

    it 'indexes the representative_id' do
      expect(subject['representative_id_ssim']).to eq monograph.representative_id
    end

    it 'indexes all filesets attached directly or via its sections' do
      expect(subject['ordered_fileset_ids_ssim']).to eq [monograph_file1.id,
                                                         section1_file1.id,
                                                         section1_file2.id,
                                                         monograph_file2.id,
                                                         section2_file1.id]
    end
  end
end
