# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crossref::Register do
  let(:xml) do
    doc = Nokogiri::XML(IO.readlines(Rails.root.join("config", "crossref", "monograph_metadata_template.xml")).join("\n"))
    doc.at_css('doi_batch_id').content = "test-batch-id"
    doc.to_xml
  end

  describe "#initialize" do
    subject { described_class.new(xml) }

    context "config" do
      it "loads the correct fields from crossref.yml" do
        expect(subject.config['deposit_url']).not_to be nil
        expect(subject.config['login_id']).not_to be nil
        expect(subject.config['login_passwd']).not_to be nil
      end
    end
  end

  describe "#post" do
    subject { described_class.new(xml).post }

    before do
      Typhoeus.stub(/crossref.org\/servlet\/deposit/).and_return(Typhoeus::Response.new(response_code: code,
                                                                                        response_body: body))
    end

    context "exercising the happy path" do
      let(:code) { 200 }
      let(:body) { "some kind of success" }

      it "returns a 200" do
        expect(subject.code).to eq 200
        expect(CrossrefSubmissionLog.count).to eq 1
        expect(CrossrefSubmissionLog.first.doi_batch_id).to eq "test-batch-id"
        expect(CrossrefSubmissionLog.first.initial_http_status).to eq code
        expect(CrossrefSubmissionLog.first.initial_http_message).to eq body
        expect(CrossrefSubmissionLog.first.submission_xml).to eq xml
        expect(CrossrefSubmissionLog.first.status).to eq "submitted"
      end
    end

    context "exercising the sad path" do
      let(:code) { 400 }
      let(:body) { "some kind of failure" }

      it "returns a 400" do
        expect(subject.code).to eq 400
        expect(CrossrefSubmissionLog.count).to eq 1
        expect(CrossrefSubmissionLog.first.doi_batch_id).to eq "test-batch-id"
        expect(CrossrefSubmissionLog.first.initial_http_status).to eq code
        expect(CrossrefSubmissionLog.first.initial_http_message).to eq body
        expect(CrossrefSubmissionLog.first.submission_xml).to eq xml
        expect(CrossrefSubmissionLog.first.status).to eq "error"
      end
    end
  end
end
