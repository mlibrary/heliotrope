# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::PlatformReport do
  let(:press) { create(:press) }

  describe "#header" do
    subject { described_class.new(params_object).report }

    let(:params_object) { CounterReporter::ReportParams.new('pr_p1', press: press.id, institution: institution, start_date: start_date, end_date: end_date) }
    let(:institution_name) { double("institution_name", name: "U of Something") }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-02-01" }
    let(:institution) { 1 }

    it "has the correct header" do
      allow(Greensub::Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      expect(subject[:header][:Report_Name]).to eq "Platform Usage"
      expect(subject[:header][:Report_ID]).to eq "PR_P1"
      expect(subject[:header][:Release]).to eq "5"
      expect(subject[:header][:Institution_Name]).to eq institution_name.name
      expect(subject[:header][:Institution_ID]).to eq institution
      expect(subject[:header][:Metric_Types]).to eq "Total_Item_Requests; Unique_Item_Requests; Unique_Title_Requests"
      expect(subject[:header][:Report_Filters]).to eq "Access_Type=Controlled; Access_Method=Regular"
      expect(subject[:header][:Report_Attributes]).to eq ""
      expect(subject[:header][:Exceptions]).to eq ""
      expect(subject[:header][:Reporting_Period]).to eq "2018-1 to 2018-2"
      expect(subject[:header][:Created]).to eq Time.zone.today.iso8601
      expect(subject[:header][:Created_By]).to eq "Fulcrum/#{press.name}"
    end
  end

  describe '#report' do
    context 'a pr_p1 report' do
      subject { described_class.new(params_object).report }

      let(:params_object) { CounterReporter::ReportParams.new('pr_p1', press: press.id, institution: institution, start_date: start_date, end_date: end_date) }
      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }
      let(:institution) { 1 }

      before do
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 10, noid: 'b',  parent_noid: 'B', institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)
        allow(Greensub::Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      it "has the correct platform" do
        expect(subject[:items][0]["Platform"]).to eq "Fulcrum/#{press.name}"
      end

      it "has the correct results" do
        expect(subject[:items][0]["Metric_Type"]).to eq "Total_Item_Requests"
        expect(subject[:items][0]["Reporting_Period_Total"]).to eq 4
        expect(subject[:items][0]["Jan-2018"]).to eq 3
        expect(subject[:items][0]["Feb-2018"]).to eq 1

        expect(subject[:items][1]["Metric_Type"]).to eq "Unique_Item_Requests"
        expect(subject[:items][1]["Reporting_Period_Total"]).to eq 3
        expect(subject[:items][1]["Jan-2018"]).to eq 2
        expect(subject[:items][1]["Feb-2018"]).to eq 1

        expect(subject[:items][2]["Metric_Type"]).to eq "Unique_Title_Requests"
        expect(subject[:items][2]["Reporting_Period_Total"]).to eq 2
        expect(subject[:items][2]["Jan-2018"]).to eq 1
        expect(subject[:items][2]["Feb-2018"]).to eq 1
      end

      context "with child presses" do
        let(:child1) { create(:press, parent: press) }
        let(:child2) { create(:press, parent: press) }

        before do
          create(:counter_report, press: child1.id, session: 11,  noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-10").utc, access_type: "Controlled", request: 1)
          create(:counter_report, press: child2.id, session: 12,  noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-01-15").utc, access_type: "Controlled", request: 1)
        end

        it "includes the childs presses in the results" do
          expect(subject[:items][0]["Metric_Type"]).to eq "Total_Item_Requests"
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 6
          expect(subject[:items][0]["Jan-2018"]).to eq 5
          expect(subject[:items][0]["Feb-2018"]).to eq 1
        end
      end
    end

    context "a pr report'" do
      subject { described_class.new(params_object).report }

      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }
      let(:institution) { 1 }

      context "for oa_gold, unique_title_investigations for a press" do
        let(:params_object) do
          CounterReporter::ReportParams.new('pr',
                                            press: press.id,
                                            institution: institution,
                                            metric_type: 'Unique_Title_Investigations',
                                            access_type: 'OA_Gold',
                                            start_date: start_date,
                                            end_date: end_date)
        end

        before do
          create(:counter_report, session: 1, press: press.id, noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
          create(:counter_report, session: 1, press: press.id, noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold", request: 1)
          create(:counter_report, session: 1, press: press.id, noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
          create(:counter_report, session: 2, press: press.id, noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-06").utc, access_type: "OA_Gold")
          create(:counter_report, session: 3, press: 2,        noid: 'c',  parent_noid: 'C', institution: 1, created_at: Time.parse("2018-02-09").utc, access_type: "OA_Gold")
        end

        it "has the correct results" do
          expect(subject[:items][0]["Metric_Type"]).to eq "Unique_Title_Investigations"
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 2
          expect(subject[:items][0]["Jan-2018"]).to eq 1
          expect(subject[:items][0]["Feb-2018"]).to eq 1
        end
      end

      context "a multi metric_type report, controlled" do
        let(:params_object) do
          CounterReporter::ReportParams.new('pr',
                                            press: press.id,
                                            institution: institution,
                                            metric_type: ['Total_Item_Investigations', 'Unique_Item_Investigations'],
                                            access_type: ['Controlled'],
                                            start_date: start_date,
                                            end_date: end_date)
        end

        before do
          create(:counter_report, session: 1, press: press.id, noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
          create(:counter_report, session: 1, press: press.id, noid: 'a2', parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold", request: 1)
          create(:counter_report, session: 1, press: press.id, noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
          create(:counter_report, session: 2, press: press.id, noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-06").utc, access_type: "Controlled")
          create(:counter_report, session: 2, press: press.id, noid: 'b',  parent_noid: 'B', institution: 1, created_at: Time.parse("2018-02-06").utc, access_type: "Controlled")
          create(:counter_report, session: 3, press: press.id, noid: 'c',  parent_noid: 'C', institution: 1, created_at: Time.parse("2018-02-09").utc, access_type: "Controlled")
        end

        it "has the correct metric types in order" do
          expect(subject[:items][0]["Metric_Type"]).to eq 'Total_Item_Investigations'
          expect(subject[:items][1]["Metric_Type"]).to eq 'Unique_Item_Investigations'
        end

        it "has fields not in a pr_p1 report (data_type, access_type, access_method)" do
          expect(subject[:items][0]["Data_Type"]).to eq "Book"
          expect(subject[:items][0]["Access_Type"]).to eq "Controlled"
          expect(subject[:items][0]["Access_Method"]).to eq "Regular"
        end

        it "has the correct results" do
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 5
          expect(subject[:items][1]["Reporting_Period_Total"]).to eq 4
        end
      end

      context "multi-institutional, Total_Item_Investigations, Controlled" do
        let(:institution) { '*' }
        let(:institution_name) { double("institution_name", name: "All Institutions") }
        let(:params_object) do
          CounterReporter::ReportParams.new('pr',
                                            press: press.id,
                                            institution: institution,
                                            metric_type: ['Total_Item_Investigations'],
                                            access_type: ['Controlled'],
                                            start_date: start_date,
                                            end_date: end_date)
        end

        before do
          create(:counter_report, session: 1, press: press.id, noid: 'a',  parent_noid: 'A', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
          create(:counter_report, session: 1, press: press.id, noid: 'a2', parent_noid: 'A', institution: 2, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
          create(:counter_report, session: 1, press: press.id, noid: 'b',  parent_noid: 'B', institution: 3, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled")
          create(:counter_report, session: 2, press: press.id, noid: 'b',  parent_noid: 'B', institution: 4, created_at: Time.parse("2018-02-06").utc, access_type: "Controlled")
          create(:counter_report, session: 2, press: press.id, noid: 'b',  parent_noid: 'B', institution: 5, created_at: Time.parse("2018-02-06").utc, access_type: "Controlled")
          create(:counter_report, session: 3, press: press.id, noid: 'c',  parent_noid: 'C', institution: 5, created_at: Time.parse("2018-02-09").utc, access_type: "Controlled")
        end

        it "has the correct results" do
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 6
        end

        it "has the correct header" do
          expect(subject[:header][:Institution_Name]).to eq 'All Institutions'
          expect(subject[:header][:Institution_ID]).to eq '*'
        end
      end
    end
  end
end
