require 'rails_helper'

describe MonographIndexer do
  let(:indexer) { described_class.new(monograph) }
  let(:monograph) { build(:monograph,
                          primary_editor_given_name: 'Bullwinkle',
                          primary_editor_family_name: 'Moose') }
  let(:file) { create(:file_set) }

  before do
    monograph.ordered_members << file
    monograph.save!
  end

  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }
    let(:press_name) { Press.find_by(subdomain: monograph.press).name }

    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [file.id]
    end

    it 'indexes the press name' do
      expect(subject['press_name_ssim']).to eq press_name
    end

    it 'indexes the representative_id' do
      expect(subject['representative_id_ssim']).to eq monograph.representative_id
    end

    it 'indexes the primary_editor_full_name' do
      expect(subject['primary_editor_full_name_tesim']).to eq 'Moose, Bullwinkle'
      expect(subject['primary_editor_full_name_sim']).to eq 'Moose, Bullwinkle'
    end
  end
end
