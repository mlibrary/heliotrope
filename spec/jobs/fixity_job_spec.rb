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

    context "no failures" do
      it "runs the fixity check, adds a row to the logs" do
        described_class.perform_now

        expect(ChecksumAuditLog.count).to eq 1
        expect(ChecksumAuditLog.first.file_set_id).to eq file_set.id
        expect(ChecksumAuditLog.first.checked_uri).to eq file_set.original_file.versions.first.uri
        expect(ChecksumAuditLog.first.passed).to be true
      end
    end

    context "with a failure" do
      let(:response) do
        {
            file_set_id: file_set.id,
            uri: file_set.original_file.versions.first.uri,
            file_id: file_set.original_file.id,
            expected_response: "uri:sha:whatever",
            passed: false,
            tries: 3
        }
      end
      let(:mailer) { double("mailer", deliver_now: true) }

      before do
        allow(FixityMailer).to receive(:send_failures).with([response]).and_return(mailer)
        allow_any_instance_of(described_class).to receive(:run_fixity_check).with(file_set.id).and_return(response)
      end

      it "send the fixity failure email, adds a row to the logs" do
        described_class.perform_now
        expect(expect(FixityMailer).to have_received(:send_failures).with([response]))
        expect(ChecksumAuditLog.count).to eq 1
        expect(ChecksumAuditLog.first.file_set_id).to eq file_set.id
        expect(ChecksumAuditLog.first.checked_uri).to eq file_set.original_file.versions.first.uri
        expect(ChecksumAuditLog.first.passed).to be false
      end
    end
  end

  describe "#run_fixity_check" do
    context "a file_set with no file" do
      let(:file_set) { create(:file_set) }

      it "returns an error" do
        response = described_class.new.run_fixity_check(file_set.id)

        expect(response[:error]).to eq "no_original_file_present"
        expect(response[:file_set_id]).to eq file_set.id
      end
    end

    context "a file_set with a file with no versions" do
      let(:file_set) { create(:file_set) }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/csv/shipwreck.jpg'), :original_file,  versioning: false)
      end

      it "returns an error" do
        response = described_class.new.run_fixity_check(file_set.id)

        expect(response[:error]).to eq "no_versions_present"
        expect(response[:file_set_id]).to eq file_set.id
      end
    end

    context "a file_set with versions" do
      let(:file_set) { create(:file_set) }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/csv/shipwreck.jpg'), :original_file)
      end

      it "returns a fixity_check response" do
        response = described_class.new.run_fixity_check(file_set.id)

        expect(response[:error]).to be nil
        expect(response[:file_set_id]).to eq file_set.id
        expect(response[:passed]).to be true
      end
    end
  end
end
