require 'rails_helper'

describe CurationConcerns::SectionForm do
  describe "#terms" do
    subject { described_class.terms }
    it { is_expected.to eq [:title,
                            :monograph_id,
                            :ordered_member_ids,
                            :visibility_during_embargo,
                            :embargo_release_date,
                            :visibility_after_embargo,
                            :visibility_during_lease,
                            :lease_expiration_date,
                            :visibility_after_lease,
                            :visibility] }
  end

  describe "#required_fields" do
    subject { described_class.required_fields }
    it { is_expected.to eq [:title, :monograph_id] }
  end
end
