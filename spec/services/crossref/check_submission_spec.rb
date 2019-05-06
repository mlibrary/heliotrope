# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crossref::CheckSubmission do
  describe '#fetch' do
    subject { described_class.new(file_name).fetch }

    before do
      Typhoeus.stub(/crossref.org\/servlet\/submissionDownload/).and_return(Typhoeus::Response.new(response_code: code,
                                                                                                   response_body: body))
    end

    # Honestly there's really not much to this right now.
    # It just returns a response from crossref.
    # So this is really all mocks/stubs of things we expect.

    context "valid existing submission" do
      let(:file_name) { 'a_valid_file_name' }
      let(:body) do
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
      let(:code) { 200 }

      it "responds" do
        expect(subject.body).to eq body
        expect(subject.code).to eq code
      end
    end

    context "invalid/missing submission" do
      let(:file_name) { 'an_invalid_file_name' }
      let(:body) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <doi_batch_diagnostic status="unknown_submission">
          <submission_id>0</submission_id>
          <batch_id />
        </doi_batch_diagnostic>
        XML
      end
      let(:code) { 200 }

      it "responds" do
        expect(subject.body).to eq body
        expect(subject.code).to eq code
      end
    end
  end
end
