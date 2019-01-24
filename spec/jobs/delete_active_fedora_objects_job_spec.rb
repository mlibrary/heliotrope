# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteActiveFedoraObjectsJob, type: :job do
  describe "perform" do
    let(:monograph) { create(:monograph) }
    let(:file_set1) { create(:file_set) }
    let(:file_set2) { create(:file_set) }

    it "deletes any AF objects whose NOIDs are passed in" do
      described_class.perform_now([monograph.id, file_set1.id, file_set2.id])
      expect(Monograph.count).to eq(0)
      expect(FileSet.count).to eq(0)
    end
  end
end
