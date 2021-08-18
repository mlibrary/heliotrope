# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FixityJob, type: :job do
  context "perform" do
    let(:monograph) { create(:monograph) }
    let(:file_set) { create(:file_set) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/csv/shipwreck.jpg'), :original_file)
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it "runs runs the fixity check" do
      described_class.perform_now

      expect(ChecksumAuditLog.count).to eq 1
      expect(ChecksumAuditLog.first.file_set_id).to eq file_set.id
      expect(ChecksumAuditLog.first.checked_uri).to eq file_set.original_file.versions.first.uri
      expect(ChecksumAuditLog.first.passed).to be true
    end
  end
end
