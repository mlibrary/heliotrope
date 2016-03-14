require 'rails_helper'

describe CurationConcerns::SectionForm do
  describe "#terms" do
    subject { described_class.terms }
    it { is_expected.to eq [:title, :monograph_id, :ordered_member_ids] }
  end

  describe "#required_fields" do
    subject { described_class.required_fields }
    it { is_expected.to eq [:title, :monograph_id] }
  end
end
