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

    context "with a timeout" do
      let(:response) do
        {
          file_set_id: file_set.id,
          checked_uri: file_set.original_file.versions.first.uri,
          file_id: file_set.original_file.id,
          expected_result: "nil",
          passed: nil,
          error: "fixity_timeout"
      }
      end

      before do
        allow_any_instance_of(described_class).to receive(:run_fixity_check).with(file_set.id).and_return(response)
      end

      it "does not add a row to the logs" do
        described_class.perform_now
        expect(ChecksumAuditLog.count).to eq 0
      end
    end

    context "a single failure" do
      let(:response) do
        {
            file_set_id: file_set.id,
            checked_uri: file_set.original_file.versions.first.uri,
            file_id: file_set.original_file.id,
            expected_result: "uri:sha:whatever",
            passed: false
        }
      end
      let(:mailer) { double("mailer", deliver_now: true) }

      before do
        allow(FixityMailer).to receive(:send_failures).with([response]).and_return(mailer)
        allow_any_instance_of(described_class).to receive(:run_fixity_check).with(file_set.id).and_return(response)
      end

      it "adds a row to the logs, does not send email" do
        described_class.perform_now
        expect(ChecksumAuditLog.count).to eq 1
        expect(ChecksumAuditLog.first.file_set_id).to eq file_set.id
        expect(ChecksumAuditLog.first.checked_uri).to eq file_set.original_file.versions.first.uri
        expect(ChecksumAuditLog.first.passed).to be false
        expect(expect(FixityMailer).not_to have_received(:send_failures).with([response]))
      end
    end

    context "a third failure after at least two previous failures" do
      let(:response) do
        {
            file_set_id: file_set.id,
            checked_uri: file_set.original_file.versions.first.uri,
            file_id: file_set.original_file.id,
            expected_result: "uri:sha:whatever",
            passed: false
        }
      end
      let(:mailer) { double("mailer", deliver_now: true) }

      before do
        allow(FixityMailer).to receive(:send_failures).with([response]).and_return(mailer)
        allow_any_instance_of(described_class).to receive(:run_fixity_check).with(file_set.id).and_return(response)
        ChecksumAuditLog.create!(response)
        ChecksumAuditLog.create!(response)
      end

      it "adds a row to the logs and sends an email" do
        described_class.perform_now
        expect(ChecksumAuditLog.count).to eq 3
        expect(ChecksumAuditLog.third.file_set_id).to eq file_set.id
        expect(ChecksumAuditLog.third.checked_uri).to eq file_set.original_file.versions.first.uri
        expect(ChecksumAuditLog.third.passed).to be false
        expect(expect(FixityMailer).to have_received(:send_failures).with([response]))
      end
    end

    context "if passed after a 1 or 2 previous recorded failure(s)" do
      let(:response) do
        {
            file_set_id: file_set.id,
            checked_uri: file_set.original_file.versions.first.uri,
            file_id: file_set.original_file.id,
            expected_result: "uri:sha:whatever",
            passed: false
        }
      end

      before do
        ChecksumAuditLog.create!(response)
        ChecksumAuditLog.create!(response)
        response[:passed] = true
        allow_any_instance_of(described_class).to receive(:run_fixity_check).with(file_set.id).and_return(response)
      end

      it "removes previous failures and only keeps the success" do
        described_class.perform_now
        expect(ChecksumAuditLog.count).to eq 1
        expect(ChecksumAuditLog.first.file_set_id).to eq file_set.id
        expect(ChecksumAuditLog.first.checked_uri).to eq file_set.original_file.versions.first.uri
        expect(ChecksumAuditLog.first.passed).to be true
      end
    end
  end

  describe "#create_or_replace" do
    let(:response) do
      {
          file_set_id: '999999999',
          checked_uri: 'http://999999999/999',
          file_id: '999999999/999',
          expected_result: "uri:sha:whatever",
          passed: false
      }
    end

    before do
      ChecksumAuditLog.create!(response)
      ChecksumAuditLog.create!(response)
    end

    it "only keeps the newest row when passed: true" do
      response[:passed] = true
      described_class.new.create_or_replace(response)
      expect(ChecksumAuditLog.count).to eq 1
      expect(ChecksumAuditLog.first.passed).to be true
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
