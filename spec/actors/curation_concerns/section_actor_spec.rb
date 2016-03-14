require 'rails_helper'

describe CurationConcerns::SectionActor do
  let(:user) { create(:user) }
  let(:actor) do
    described_class.new(curation_concern, user, attributes)
  end

  describe "#create" do
    let(:curation_concern) { Section.new }
    let(:monograph) { create(:monograph) }
    let(:attributes) { { title: ["This is a title."],
                         monograph_id: monograph.id } }

    it 'adds the section to the monograph' do
      expect(actor.create).to be true
      expect(monograph.reload.ordered_members.to_a.size).to eq 1
    end
  end

  describe "reorder the attached files" do
    let(:curation_concern) { create(:section) }
    let!(:file_set1) { create(:file_set) }
    let!(:file_set2) { create(:file_set) }
    before do
      curation_concern.ordered_members << file_set1
      curation_concern.ordered_members << file_set2
      curation_concern.save!
    end
    let(:attributes) { { ordered_member_ids: [file_set2.id, file_set1.id] } }
    it 'sets the order of the files in the section' do
      expect(actor.update).to be true
      expect(curation_concern.reload.ordered_member_ids).to eq [file_set2.id, file_set1.id]
    end
  end
end
