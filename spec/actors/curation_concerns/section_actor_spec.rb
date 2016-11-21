require 'rails_helper'

describe CurationConcerns::Actors::SectionActor do
  let(:user) { create(:user) }
  let(:list_of_actors) { [described_class] }
  let(:actor) { CurationConcerns::Actors::ActorStack.new(curation_concern, user, list_of_actors) }

  describe "#create" do
    let(:curation_concern) { Section.new }
    let(:monograph) { create(:public_monograph) }
    let(:attributes) { { title: ["This is a title."],
                         monograph_id: monograph.id } }

    let(:private_attributes) { { title: ["This is a private section title."],
                                 monograph_id: monograph.id,
                                 visibility: 'restricted' } }

    it 'adds the section to the monograph' do
      expect(actor.create(attributes)).to be true
      expect(monograph.reload.ordered_members.to_a.size).to eq 1
    end

    it "adds the monograph visibility to the section" do
      expect(actor.create(attributes)).to be true
      expect(Section.first.visibility).to eq monograph.visibility
    end

    it "adds the section visibility to the section" do
      expect(actor.create(private_attributes)).to be true
      expect(Section.first.visibility).to eq 'restricted'
    end

    it "adds the monograph_id to the section" do
      expect(actor.create(attributes)).to be true
      expect(Section.first.monograph_id).to eq monograph.id
    end
  end

  describe "#update" do
    let(:curation_concern) { Section.new }
    let(:monograph) { create(:monograph) }
    let(:attributes) { { title: ["This is a section title."],
                         monograph_id: monograph.id } }

    # bug #178
    it "does not re-add the section to monograph.ordered_members on update" do
      expect(actor.create(attributes)).to be true
      expect(monograph.reload.ordered_members.to_a.size).to eq 1

      expect(actor.update(attributes)).to be true
      expect(monograph.reload.ordered_members.to_a.size).to eq 1
    end
  end

  # TODO: Write a higher-level test for re-ordering the files
  # that are attached to a section.  This is no longer the right
  # place to test that behavior because the ordering is no
  # longer handled by the SectionActor itself.  (As of v0.12.0
  # of curation_concerns, ordering is done by
  # CurationConcerns::ApplyOrderActor).
  describe "reorder the attached files" do
    let(:list_of_actors) { [CurationConcerns::Actors::ApplyOrderActor, described_class] }

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
      expect(actor.update(attributes)).to be true
      expect(curation_concern.reload.ordered_member_ids).to eq [file_set2.id, file_set1.id]
    end
  end
end
