# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporterService do
  describe '#csv' do
    let(:institution) { 1 }
    let(:institution_name) { double("institution_name", name: "U of Something") }
    let(:created_date) { Time.zone.today.iso8601 }

    context "with no data" do
      let(:report) { described_class.tr_b1(institution: institution, start_date: "2018-01-01", end_date: "2018-03-01") }

      it "makes an empty report" do
        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])

        expect(described_class.csv(report)).to eq <<~CSV
          Report_Name,Book Requests (Excluding OA_Gold)
          Report_ID,TR_B1
          Release,5
          Institution_Name,U of Something
          Institution_ID,1
          Metric_Types,Total_Item_Requests; Unique_Title_Requests
          Report_Filters,Data_Type=Book; Access_Type=Controlled; Access_Method=Regular
          Report_Attributes,""
          Exceptions,""
          Reporting_Period,2018-1 to 2018-3
          Created,#{created_date}
          Created_By,Fulcrum

          Report is empty,""
        CSV
      end
    end

    context "with counter data" do
      let(:report) { described_class.pr_p1(institution: institution, start_date: "2018-01-01", end_date: "2018-03-01") }

      before do
        create(:counter_report, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
      end

      after { CounterReport.destroy_all }

      it "makes the csv report" do
        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])

        expect(described_class.csv(report)).to eq <<~CSV
          Report_Name,Platform Usage,"","","",""
          Report_ID,PR_P1,"","","",""
          Release,5,"","","",""
          Institution_Name,U of Something,"","","",""
          Institution_ID,1,"","","",""
          Metric_Types,Total_Item_Requests; Unique_Item_Requests; Unique_Title_Requests,"","","",""
          Report_Filters,Access_Type=Controlled; Access_Method=Regular,"","","",""
          Report_Attributes,"","","","",""
          Exceptions,"","","","",""
          Reporting_Period,2018-1 to 2018-3,"","","",""
          Created,#{created_date},"","","",""
          Created_By,Fulcrum,"","","",""
          "","","","","",""
          Platform,Metric_Type,Reporting_Period_Total,Jan-2018,Feb-2018,Mar-2018
          Fulcrum,Total_Item_Requests,2,1,1,0
          Fulcrum,Unique_Item_Requests,2,1,1,0
          Fulcrum,Unique_Title_Requests,2,1,1,0
        CSV
      end
    end
  end
end
