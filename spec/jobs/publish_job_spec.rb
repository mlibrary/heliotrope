# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob, type: :job do
  describe "perform" do
    let(:monograph) { build(:monograph) }
    let(:file_set) { create(:file_set) }

    before do
      monograph.members << file_set
      monograph.save!
    end

    it "sets the date published" do
      expect(monograph.date_published).to eq []
      described_class.perform_now(monograph)
      expect(monograph.date_published.first).not_to be_nil
      expect(file_set.reload.date_published.first).not_to be_nil

      expect(monograph.read_groups).to eq ['public']
      expect(file_set.read_groups).to eq ['public']
    end
  end
end
