# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographIndexer do
  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(monograph) }
    let(:monograph) { build(:monograph,
                            creator: ["Moose, Bullwinkle\nSquirrel, Rocky"],
                            description: ["This is the abstract"]) }
    let(:file_set) { create(:file_set) }
    let(:press_name) { Press.find_by(subdomain: monograph.press).name }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end

    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [file_set.id]
    end

    it 'indexes the press name' do
      expect(subject['press_name_ssim']).to eq press_name
    end

    it 'indexes the representative_id' do
      expect(subject['representative_id_ssim']).to eq monograph.representative_id
    end

    it 'indexes the first creator\'s full_name' do
      expect(subject['creator_full_name_tesim']).to eq 'Moose, Bullwinkle'
      expect(subject['creator_full_name_sim']).to eq 'Moose, Bullwinkle'
    end

    it 'has description indexed by Hyrax::IndexesBasicMetadata' do
      expect(subject['description_tesim'].first).to eq 'This is the abstract'
    end
  end

  describe 'empty creator field' do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(monograph) }
    let(:monograph) { build(:monograph,
                            contributor: ["Moose, Bullwinkle\nSquirrel, Rocky"])}
    before do
      monograph.save!
    end

    it 'promotes the first contributor to creator' do
      expect(subject['creator_tesim']).to eq ['Moose, Bullwinkle']
      expect(subject['contributor_tesim']).to eq ['Squirrel, Rocky']
    end
  end
end
