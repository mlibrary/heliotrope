# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crossref::Register do
  let(:xml) { IO.readlines(Rails.root.join("config", "crossref", "monograph_metadata_template.xml")).first }

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
      allow_any_instance_of(described_class).to receive(:doi_batch_id).and_return("test-batch-id")
      Typhoeus.stub(/crossref.org\/servlet\/deposit/).and_return(Typhoeus::Response.new(response_code: code))
    end

    context "exercising the happy path" do
      let(:code) { 200 }

      it "returns a 200" do
        expect(subject.code).to eq 200
      end
    end

    context "exercising the sad path" do
      let(:code) { 400 }

      it "returns a 400" do
        expect(subject.code).to eq 400
      end
    end
  end
end
