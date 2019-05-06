# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrossrefPollJob, type: :job do
  context "crossref responses" do
    let(:file_name) { 'file1' }
    let(:submissions) { [create(:crossref_submission_log, file_name: 'file1', status: 'submitted')] }
    let(:fetch) { double('fetch', fetch: response) }
    let(:response) { double('response', body: xml) }

    before do
      allow(Crossref::CheckSubmission).to receive(:new).with(file_name).and_return(fetch)
    end

    context "a successful crossref response" do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <doi_batch_diagnostic status="completed" sp="a-cs1">
          <submission_id>1427714659</submission_id>
          <batch_id>some-batch-id</batch_id>
          <record_diagnostic status="Success">
            <doi>10.3998/heliotrope.3j333224f</doi>
            <msg>Successfully added</msg>
          </record_diagnostic>
          <batch_data>
            <record_count>1</record_count>
            <success_count>1</success_count>
            <warning_count>0</warning_count>
            <failure_count>0</failure_count>
          </batch_data>
        </doi_batch_diagnostic>
        XML
      end

      it "changes the submission status to success" do
        described_class.perform_now(submissions, 0)
        expect(CrossrefSubmissionLog.first.status).to eq 'success'
      end
    end

    context "an error crossref response" do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <doi_batch_diagnostic status="completed" sp="a-cs1">
          <submission_id>1427714659</submission_id>
          <batch_id>some-batch-id</batch_id>
          <record_diagnostic status="Failure">
            <doi />
            <msg>Error: cvc-complex-type.4: Attribute 'reason' must appear on element 'noisbn'.</msg>
          </record_diagnostic>
          <batch_data>
            <record_count>1</record_count>
            <success_count>0</success_count>
            <warning_count>0</warning_count>
            <failure_count>1</failure_count>
          </batch_data>
        </doi_batch_diagnostic>
        XML
      end

      it "changes the submission status to error" do
        described_class.perform_now(submissions, 0)
        expect(CrossrefSubmissionLog.first.status).to eq 'error'
      end
    end

    context "no response from crossref" do
      let(:xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <doi_batch_diagnostic status="unknown_submission">
          <submission_id>0</submission_id>
          <batch_id />
        </doi_batch_diagnostic>
        XML
      end

      it "will be re-run a number of times and eventually set submission status to adandoned" do
        described_class.perform_now(submissions, 0)
        expect(CrossrefSubmissionLog.first.status).to eq 'abandoned'
      end
    end
  end

  context "submissions that are not 'submitted' status" do
    let(:submissions) do
      [
        create(:crossref_submission_log, file_name: 'file1', status: 'error'),
        create(:crossref_submission_log, file_name: 'file2', status: 'success')
      ]
    end

    it "does not query crossref" do
      allow(Crossref::CheckSubmission).to receive(:new)
      described_class.perform_now(submissions, 0)
      expect(Crossref::CheckSubmission).not_to have_received(:new)
    end
  end

  context "when there are too many tries" do
    let(:submissions) do
      [
        create(:crossref_submission_log, file_name: 'file1', status: 'submitted'),
        create(:crossref_submission_log, file_name: 'file2', status: 'submitted')
      ]
    end

    it "does not query crossref and statuses are set to 'abandoned'" do
      allow(Crossref::CheckSubmission).to receive(:new)
      described_class.perform_now(submissions, 0, 5)
      expect(Crossref::CheckSubmission).not_to have_received(:new)
      expect(CrossrefSubmissionLog.first.status).to eq 'abandoned'
      expect(CrossrefSubmissionLog.second.status).to eq 'abandoned'
    end
  end
end
