# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporterService do
  let(:press) { create(:press) }
  let(:institution) { instance_double(Greensub::Institution, 'institution', identifier: 1, name: "U of Something", ror_id: 'ror') }

  before { allow(Greensub::Institution).to receive(:find_by).with(identifier: institution.identifier).and_return(institution) }

  describe '#csv' do
    let(:created_date) { Time.zone.today.iso8601 }

    context "with no data" do
      let(:report) { described_class.tr_b1(press: press.id, institution: institution.identifier, start_date: "2018-01-01", end_date: "2018-03-01") }

      it "makes an empty report" do
        expect(described_class.csv(report)).to eq <<~CSV
          Report_Name,Book Requests (Excluding OA_Gold)
          Report_ID,TR_B1
          Release,5
          Institution_Name,U of Something
          Institution_ID,ID:1; ROR:ror
          Metric_Types,Total_Item_Requests; Unique_Title_Requests
          Report_Filters,Platform=#{press.subdomain}; Data_Type=Book; Access_Type=Controlled; Access_Method=Regular
          Report_Attributes,""
          Exceptions,""
          Reporting_Period,Begin_Date=2018-01-01; End_Date=2018-03-31
          Created,#{created_date}
          Created_By,Fulcrum/#{press.name}

          Report is empty,""
        CSV
      end
    end

    context "with no report header" do
      let(:report) { described_class.pr_p1(press: press.id, institution: institution.identifier, start_date: "2018-01-01", end_date: "2018-03-01") }

      before do
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", search: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", search: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
      end

      after { CounterReport.destroy_all }

      it "makes the csv report with no report header" do
        report.delete(:header)

        expect(described_class.csv(report)).to eq <<~CSV
          Platform,Metric_Type,Reporting_Period_Total,Jan-2018,Feb-2018,Mar-2018
          Fulcrum/#{press.name},Searches_Platform,2,1,1,0
          Fulcrum/#{press.name},Total_Item_Requests,2,1,1,0
          Fulcrum/#{press.name},Unique_Item_Requests,2,1,1,0
          Fulcrum/#{press.name},Unique_Title_Requests,2,1,1,0
        CSV
      end
    end

    context "with counter data" do
      let(:report) { described_class.pr_p1(press: press.id, institution: institution.identifier, start_date: "2018-01-01", end_date: "2018-03-01") }

      before do
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", search: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", search: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
      end

      after { CounterReport.destroy_all }

      it "makes the csv report" do
        expect(described_class.csv(report)).to eq <<~CSV
          Report_Name,Platform Usage,"","","",""
          Report_ID,PR_P1,"","","",""
          Release,5,"","","",""
          Institution_Name,U of Something,"","","",""
          Institution_ID,ID:1; ROR:ror,"","","",""
          Metric_Types,Searches_Platform; Total_Item_Requests; Unique_Item_Requests; Unique_Title_Requests,"","","",""
          Report_Filters,Platform=#{press.subdomain}; Data_Type=Book; Access_Type=Controlled; Access_Method=Regular,"","","",""
          Report_Attributes,"","","","",""
          Exceptions,"","","","",""
          Reporting_Period,Begin_Date=2018-01-01; End_Date=2018-03-31,"","","",""
          Created,#{created_date},"","","",""
          Created_By,Fulcrum/#{press.name},"","","",""
          "","","","","",""
          Platform,Metric_Type,Reporting_Period_Total,Jan-2018,Feb-2018,Mar-2018
          Fulcrum/#{press.name},Searches_Platform,2,1,1,0
          Fulcrum/#{press.name},Total_Item_Requests,2,1,1,0
          Fulcrum/#{press.name},Unique_Item_Requests,2,1,1,0
          Fulcrum/#{press.name},Unique_Title_Requests,2,1,1,0
        CSV
      end
    end
  end
end
