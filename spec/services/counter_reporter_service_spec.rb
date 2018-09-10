# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporterService do
  describe "#pr_p1" do
    # See https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188

    subject { described_class.pr_p1(institution: institution, start_date: start_date, end_date: end_date) }

    let(:institution_name) { double("institution_name", name: "U of Something") }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-12-01" }

    after { CounterReport.destroy_all }

    context "header" do
      let(:institution) { 1 }

      it do
        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])

        expect(subject[:header][:Report_Name]).to eq "Platform Usage"
        expect(subject[:header][:Report_ID]).to eq "PR_P1"
        expect(subject[:header][:Release]).to eq "5"
        expect(subject[:header][:Institution_Name]).to eq institution_name.name
        expect(subject[:header][:Institution_ID]).to eq institution
        expect(subject[:header][:Metric_Types]).to eq "Total_Item_Requests; Unique_Item_Requests; Unique_Title_Requests"
        expect(subject[:header][:Report_Filters]).to eq "Access_Type=Controlled; Access_Method=Regular"
        expect(subject[:header][:Report_Attributes]).to eq ""
        expect(subject[:header][:Exceptions]).to eq ""
        expect(subject[:header][:Reporting_Period]).to eq "#{start_date} to #{end_date}"
        expect(subject[:header][:Created]).to eq Time.zone.today.iso8601
        expect(subject[:header][:Created_By]).to eq "Fulcrum"
      end
    end

    context "no press" do
      let(:institution) { 1 }

      before do
        create(:counter_report, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
        create(:counter_report, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 1,  noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 10, noid: 'b',  parent_noid: 'B', institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)
      end

      after { CounterReport.destroy_all }

      it do
        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])

        expect(subject[:items][0]["Metric_Type"]).to eq "Total_Item_Requests"
        expect(subject[:items][0]["Reporting_Period_Total"]).to eq 4
        expect(subject[:items][0]["Jan-2018"]).to eq 3
        expect(subject[:items][0]["Nov-2018"]).to eq 1

        expect(subject[:items][1]["Metric_Type"]).to eq "Unique_Item_Requests"
        expect(subject[:items][1]["Reporting_Period_Total"]).to eq 3
        expect(subject[:items][1]["Jan-2018"]).to eq 2
        expect(subject[:items][1]["Nov-2018"]).to eq 1

        expect(subject[:items][2]["Metric_Type"]).to eq "Unique_Title_Requests"
        expect(subject[:items][2]["Reporting_Period_Total"]).to eq 2
        expect(subject[:items][2]["Jan-2018"]).to eq 1
        expect(subject[:items][2]["Nov-2018"]).to eq 1
      end
    end

    context "limit by press" do
      subject { described_class.pr_p1(institution: institution, start_date: start_date, end_date: end_date, press: 1) }

      let(:institution) { 1 }

      before do
        create(:press, id: 1, subdomain: "this_press")
        create(:press, id: 2, subdomain: "other_press")
        create(:counter_report, press: 1, session: 1, noid: 'a', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: 1, session: 2, noid: 'b', parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: 2, session: 3, noid: 'c', parent_noid: 'C', institution: 1, created_at: Time.parse("2018-03-11").utc, access_type: "Controlled", request: 1)
      end

      after do
        Press.destroy_all
        CounterReport.destroy_all
      end

      it do
        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])

        expect(subject[:items][0]["Reporting_Period_Total"]).to eq 2 # Total_Item_Requests
        expect(subject[:items][1]["Reporting_Period_Total"]).to eq 2 # Unique_Item_Requests
        expect(subject[:items][2]["Reporting_Period_Total"]).to eq 2 # Unique_Title_Requests
      end
    end
  end
end
