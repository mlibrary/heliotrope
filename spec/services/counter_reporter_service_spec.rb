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
        expect(subject[:header][:Reporting_Period]).to eq "2018-1 to 2018-12"
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

  describe '#tr_b1' do
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1559300549
    subject { described_class.tr_b1(institution: institution, start_date: start_date, end_date: end_date) }

    let(:institution_name) { double("institution_name", name: "U of Something") }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-12-01" }
    let(:institution) { 1 }

    let(:red) do
      ::SolrDocument.new(id: 'red',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Red'],
                         publisher_tesim: ["R"],
                         isbn_tesim: ['111', '222'])
    end
    let(:green) do
      ::SolrDocument.new(id: 'green',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Green'],
                         publisher_tesim: ["G"],
                         isbn_tesim: ['AAA', 'BBB'])
    end
    let(:blue) do
      ::SolrDocument.new(id: 'blue',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Blue'],
                         publisher_tesim: ["B"],
                         isbn_tesim: ['ZZZ', 'YYY'])
    end

    before do
      ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h])
      ActiveFedora::SolrService.commit

      create(:counter_report, session: 1,  noid: 'a',  parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, session: 1,  noid: 'a2', parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, session: 1,  noid: 'b',  parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, session: 6,  noid: 'c',  parent_noid: 'green', institution: 1, created_at: Time.parse("2018-05-11").utc, access_type: "Controlled", request: 1)
      create(:counter_report, session: 7,  noid: 'c1', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-11-03").utc, access_type: "Controlled", request: 1)
      create(:counter_report, session: 10, noid: 'a',  parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)

      allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
    end

    context "items" do
      it "has the correct number of items" do
        expect(subject[:items].length).to be 6
      end

      it "each title has 2 rows" do
        expect(subject[:items][0]["Title"]).to eq "Red"
        expect(subject[:items][1]["Title"]).to eq "Red"
        expect(subject[:items][2]["Title"]).to eq "Blue"
        expect(subject[:items][3]["Title"]).to eq "Blue"
        expect(subject[:items][4]["Title"]).to eq "Green"
        expect(subject[:items][5]["Title"]).to eq "Green"
      end

      it "each title has a metric type Total_Item_Requests and then metric type Unique_Title_Requests" do
        expect(subject[:items][0]["Metric_Type"]).to eq "Total_Item_Requests"
        expect(subject[:items][1]["Metric_Type"]).to eq "Unique_Title_Requests"
        expect(subject[:items][2]["Metric_Type"]).to eq "Total_Item_Requests"
        expect(subject[:items][3]["Metric_Type"]).to eq "Unique_Title_Requests"
        expect(subject[:items][4]["Metric_Type"]).to eq "Total_Item_Requests"
        expect(subject[:items][5]["Metric_Type"]).to eq "Unique_Title_Requests"
      end

      it "each titles total requests are correct" do
        # red total item requests
        expect(subject[:items][0]["Reporting_Period_Total"]).to eq 2
        # red unique title requests
        expect(subject[:items][1]["Reporting_Period_Total"]).to eq 1
        # blue total item requests
        expect(subject[:items][2]["Reporting_Period_Total"]).to eq 1
        # blue unique title requests
        expect(subject[:items][3]["Reporting_Period_Total"]).to eq 1
        # green total item requests
        expect(subject[:items][4]["Reporting_Period_Total"]).to eq 2
        # green unique title requests
        expect(subject[:items][5]["Reporting_Period_Total"]).to eq 2
      end

      it "each title's monthly reporting is correct" do
        # red total item requests
        expect(subject[:items][0]["Jan-2018"]).to eq 2
        expect(subject[:items][0]["Mar-2018"]).to eq 0
        # red unique title requests
        expect(subject[:items][1]["Jan-2018"]).to eq 1
        # blue total item requests
        expect(subject[:items][2]["Jan-2018"]).to eq 1
        # blue unique title requests
        expect(subject[:items][3]["Jan-2018"]).to eq 1
        expect(subject[:items][3]["Jul-2018"]).to eq 0
        # green total item requests
        expect(subject[:items][4]["May-2018"]).to eq 1
        expect(subject[:items][4]["Nov-2018"]).to eq 1
        expect(subject[:items][4]["Dec-2018"]).to eq 0
        # green unique title requests
        expect(subject[:items][5]["May-2018"]).to eq 1
        expect(subject[:items][5]["Nov-2018"]).to eq 1
      end
    end

    context "header" do
      it do
        expect(subject[:header][:Report_Name]).to eq "Book Requests (Excluding OA_Gold)"
        expect(subject[:header][:Report_ID]).to eq "TR_B1"
        expect(subject[:header][:Release]).to eq "5"
        expect(subject[:header][:Institution_Name]).to eq institution_name.name
        expect(subject[:header][:Institution_ID]).to eq institution
        expect(subject[:header][:Metric_Types]).to eq "Total_Item_Requests; Unique_Title_Requests"
        expect(subject[:header][:Report_Filters]).to eq "Data_Type=Book; Access_Type=Controlled; Access_Method=Regular"
        expect(subject[:header][:Report_Attributes]).to eq ""
        expect(subject[:header][:Exceptions]).to eq ""
        expect(subject[:header][:Reporting_Period]).to eq "2018-1 to 2018-12"
        expect(subject[:header][:Created]).to eq Time.zone.today.iso8601
        expect(subject[:header][:Created_By]).to eq "Fulcrum"
      end
    end
  end
end
