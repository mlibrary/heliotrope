require 'rails_helper'

RSpec.describe ReindexFileSetJob, type: :job do
  describe "perform" do
    let(:monograph) { create(:monograph) }
    let(:section) { create(:section) }
    let(:file_set) { create(:file_set) }
    before do
      monograph.ordered_members << section
      monograph.save!
      section.ordered_members << file_set
      section.save!
    end

    context "when a section has a new title" do
      before do
        section.title = ["new title"]
        section.save!
      end
      it "reindexes the file_set with the new section title" do
        described_class.perform_now(file_set)
        doc = FileSetIndexer.new(file_set).generate_solr_document
        expect(doc.to_h["section_title_tesim"]).to eq ["new title"]
      end
    end
  end
end
