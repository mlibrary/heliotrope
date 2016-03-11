require 'rails_helper'

describe CurationConcerns::SectionActor do
  let(:user) { create(:user) }
  let(:curation_concern) { Section.new }
  let(:actor) do
    described_class.new(curation_concern, user, attributes)
  end

  describe "#create" do
    let(:monograph) { create(:monograph) }
    let(:attributes) { { title: ["This is a title."],
                         monograph_id: monograph.id } }

    it 'adds the section to the monograph' do
      expect(actor.create).to be true
      expect(monograph.reload.members.size).to eq 1
    end
  end
end
