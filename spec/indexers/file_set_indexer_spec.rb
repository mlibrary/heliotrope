require 'rails_helper'

describe FileSetIndexer do
  let(:indexer) { described_class.new(file_set) }
  let(:monograph) { create(:monograph) }
  let(:section) { create(:section) }
  let(:file_set) { create(:file_set) }

  before do
    monograph.ordered_members << section
    section.ordered_members << file_set
    monograph.save!
    section.save!
  end

  describe "indexing a file_set" do
    subject { indexer.generate_solr_document }

    it "indexes it's section_title" do
      expect(subject['section_title_tesim']).to eq section.title
    end
  end
end
