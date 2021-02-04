# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstitutionReportService do
  describe "#run" do
    let(:press) { create(:press, subdomain: "blue", name: "The Blue Press") }
    let(:inst1) { double("inst1", name: "One Institution", identifier: "1") }
    let(:inst2) { double("inst2", name: "Two Institution", identifier: "2") }

    before do
      allow(Greensub::Institution).to receive(:all).and_return([inst1, inst2])
      create(:counter_report, press: press.id, session: 1,  request: 1, noid: 'a',  parent_noid: 'red', institution: inst1.identifier, created_at: Time.parse("2018-01-01").utc)
      create(:counter_report, press: press.id, session: 2,  request: 1, noid: 'b',  parent_noid: 'gar', institution: inst2.identifier, created_at: Time.parse("2018-01-03").utc)
      create(:counter_report, press: press.id, session: 3,  request: 1, noid: 'c',  parent_noid: 'luf', institution: inst2.identifier, created_at: Time.parse("2018-02-03").utc)
    end

    context "without provided institutions" do
      let(:args) do
        {
          press: press.id,
          start_date: "2018-01-01",
          end_date: "2018-02-28",
          report_type: "request"
        }
      end
      let(:results) do
        {
          "One Institution": { "Jan-2018": 1, "Feb-2018": 0 },
          "Two Institution": { "Jan-2018": 1, "Feb-2018": 1 }
        }.with_indifferent_access
      end

      it "returns the correct results" do
        expect(described_class.run(args: args)).to eq results
      end
    end

    context "with provided institutions" do
      let(:args) do
        {
          press: press.id,
          start_date: "2018-01-01",
          end_date: "2018-02-28",
          report_type: "request",
          institutions: [inst2]
        }
      end
      let(:results) do
        {
          "Two Institution": { "Jan-2018": 1, "Feb-2018": 1 }
        }.with_indifferent_access
      end

      it "returns the correct results" do
        expect(described_class.run(args: args)).to eq results
      end
    end
  end

  describe "#make_csv" do
    let(:report_heading) { "This is the report name" }
    let(:results) do
      {
        "One Institution": { "Jan-2018": 1, "Feb-2018": 0 },
        "Two Institution": { "Jan-2018": 1, "Feb-2018": 1 }
      }
    end

    let(:csv) do
      <<-CSV
#{report_heading},"",""
"",Jan-2018,Feb-2018
One Institution,1,0
Two Institution,1,1
      CSV
    end

    it "returns a csv formatted string" do
      expect(described_class.make_csv(subject: report_heading, results: results)).to eq csv
    end
  end
end
