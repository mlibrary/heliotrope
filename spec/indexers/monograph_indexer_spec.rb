require 'rails_helper'

describe MonographIndexer do
  let(:indexer) { described_class.new(monograph) }

  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }
    let(:monograph) { build(:monograph,
                            creator_family_name: 'Shakespeare',
                            creator_given_name: 'W.') }

    it 'indexes the full name of the creator' do
      expect(subject['creator_full_name_tesim']).to eq 'Shakespeare, W.'
      expect(subject['creator_full_name_sim']).to eq 'Shakespeare, W.'
    end

    context 'with relationships to members and press' do
      let(:monograph) { create(:monograph) }
      let(:chapter1) { create(:section) }
      let(:file) { create(:file_set) }
      let(:press_name) { Press.find_by(subdomain: monograph.press).name }

      before do
        monograph.ordered_members << file
        monograph.ordered_members << chapter1
        monograph.save!
      end

      it 'indexes the ordered members' do
        expect(subject['ordered_member_ids_ssim']).to eq [file.id, chapter1.id]
      end

      it 'indexes the press name' do
        expect(subject['press_name_ssim']).to eq press_name
      end
    end
  end
end
