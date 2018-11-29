# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::TitleReport do
  let(:press) { create(:press) }

  describe "#results_by_month" do
    subject { described_class.new(params_object).results_by_month }

    let(:params_object) { CounterReporter::ReportParams.new('tr', params) }
    let(:params) do
      {
        institution: institution,
        press: press.id,
        metric_type: 'Total_Item_Investigations',
        start_date: start_date,
        end_date: end_date,
        access_type: 'OA_Gold'
      }
    end
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-03-30" }
    let(:institution) { 1 }

    before do
      create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
      create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
      create(:counter_report, press: press.id, session: 1,  noid: 'b',  parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
      create(:counter_report, press: press.id, session: 6,  noid: 'c',  parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "OA_Gold")
      create(:counter_report, press: press.id, session: 7,  noid: 'c1', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-03-03").utc, access_type: "OA_Gold")
      create(:counter_report, press: press.id, session: 10, noid: 'a',  parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "OA_Gold")
    end

    it "has the correct results" do
      expect(subject).to eq("Jan-2018" => { "total_item_investigations" => { "oa_gold" => { "blue" => 1, "red" => 2 } } },
                            "Feb-2018" => { "total_item_investigations" => { "oa_gold" => { "green" => 1 } } },
                            "Mar-2018" => { "total_item_investigations" => { "oa_gold" => { "green" => 1 } } })
    end
  end

  describe '#report' do
    subject { described_class.new(params_object).report }

    let(:red) do
      ::SolrDocument.new(id: 'red',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Red'],
                         publisher_tesim: ["R"],
                         isbn_tesim: ['111', '222'],
                         date_created_tesim: ['2000'])
    end
    let(:green) do
      ::SolrDocument.new(id: 'green',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Green'],
                         publisher_tesim: ["G"],
                         isbn_tesim: ['AAA', 'BBB'],
                         date_created_tesim: ['2000'])
    end
    let(:blue) do
      ::SolrDocument.new(id: 'blue',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Blue'],
                         publisher_tesim: ["B"],
                         isbn_tesim: ['ZZZ', 'YYY'],
                         date_created_tesim: ['1999'])
    end

    context 'a full tr_b1 report' do
      # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1559300549
      let(:params_object) { CounterReporter::ReportParams.new('tr_b1', press: press.id, institution: institution, start_date: start_date, end_date: end_date) }
      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-12-01" }
      let(:institution) { 1 }

      before do
        ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'b',  parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'c',  parent_noid: 'green', institution: 1, created_at: Time.parse("2018-05-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 7,  noid: 'c1', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-11-03").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 10, noid: 'a',  parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)

        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      context "items" do
        it "has the correct platform" do
          expect(subject[:items][0]["Platform"]).to eq "Fulcrum/#{press.name}"
        end

        it "has the correct number of items" do
          expect(subject[:items].length).to be 6
        end

        it "each title has 2 rows with titles in alphabetical order" do
          expect(subject[:items][0]["Title"]).to eq "Blue"
          expect(subject[:items][1]["Title"]).to eq "Blue"
          expect(subject[:items][2]["Title"]).to eq "Green"
          expect(subject[:items][3]["Title"]).to eq "Green"
          expect(subject[:items][4]["Title"]).to eq "Red"
          expect(subject[:items][5]["Title"]).to eq "Red"
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
          # blue total item requests
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 1
          # blue unique title requests
          expect(subject[:items][1]["Reporting_Period_Total"]).to eq 1
          # green total item requests
          expect(subject[:items][2]["Reporting_Period_Total"]).to eq 2
          # green unique title requests
          expect(subject[:items][3]["Reporting_Period_Total"]).to eq 2
          # red total item requests
          expect(subject[:items][4]["Reporting_Period_Total"]).to eq 2
          # red unique title requests
          expect(subject[:items][5]["Reporting_Period_Total"]).to eq 1
        end

        it "each title's monthly reporting is correct" do
          # blue total item requests
          expect(subject[:items][0]["Jan-2018"]).to eq 1
          # blue unique title requests
          expect(subject[:items][1]["Jan-2018"]).to eq 1
          expect(subject[:items][1]["Jul-2018"]).to eq 0
          # green total item requests
          expect(subject[:items][2]["May-2018"]).to eq 1
          expect(subject[:items][2]["Nov-2018"]).to eq 1
          expect(subject[:items][2]["Dec-2018"]).to eq 0
          # green unique title requests
          expect(subject[:items][3]["May-2018"]).to eq 1
          expect(subject[:items][3]["Nov-2018"]).to eq 1
          # red total item requests
          expect(subject[:items][4]["Jan-2018"]).to eq 2
          expect(subject[:items][4]["Mar-2018"]).to eq 0
          # red unique title requests
          expect(subject[:items][5]["Jan-2018"]).to eq 1
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
          expect(subject[:header][:Created_By]).to eq "Fulcrum/#{press.name}"
        end
      end
    end

    context "a tr report including Year of Publications" do
      let(:params_object) do
        CounterReporter::ReportParams.new('tr', institution: institution,
                                                press: press.id,
                                                start_date: start_date,
                                                end_date: end_date,
                                                yop: yop,
                                                metric_type: metric_type,
                                                access_type: access_type)
      end
      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }
      let(:institution) { 1 }
      let(:yop) { '2000' }
      let(:access_type) { 'OA_Gold' }
      let(:metric_type) { 'Total_Item_Investigations' }

      before do
        ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, press: press.id, session: 1,  noid: 'a', parent_noid: 'red', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'red', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
        # "blue" was published in 1999
        create(:counter_report, press: press.id, session: 1,  noid: 'b', parent_noid: 'blue', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "OA_Gold")
        create(:counter_report, press: press.id, session: 6,  noid: 'c', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "OA_Gold")
        # A monograph investigation from the monograph_catalog page
        create(:counter_report, press: press.id, session: 7,  noid: 'green', model: 'Monograph', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-13").utc, access_type: "OA_Gold")
        create(:counter_report, press: press.id, session: 10, noid: 'a', parent_noid: 'red', institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "OA_Gold")

        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      context "items" do
        it "has the correct number of items" do
          expect(subject[:items].length).to eq 2
        end

        it "has the correct titles in order" do
          expect(subject[:items][0]["Title"]).to eq 'Green'
          expect(subject[:items][1]["Title"]).to eq 'Red'
        end

        it "has the correct counts" do
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 2
          expect(subject[:items][1]["Reporting_Period_Total"]).to eq 2
        end

        it "has the correct monthly counts" do
          expect(subject[:items][0]["Jan-2018"]).to eq 0
          expect(subject[:items][0]["Feb-2018"]).to eq 2
          expect(subject[:items][1]["Jan-2018"]).to eq 2
          expect(subject[:items][1]["Feb-2018"]).to eq 0
        end
      end
    end

    context "a tr_b2 report" do
      let(:params_object) { CounterReporter::ReportParams.new('tr_b2', params) }
      let(:params) do
        {
          press: press.id,
          institution: institution,
          start_date: start_date,
          end_date: end_date
        }
      end
      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-08-01" }
      let(:end_date) { "2018-09-01" }
      let(:institution) { 1 }

      before do
        ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled", turnaway: "No_License")
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 1,  noid: 'b',  parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled", turnaway: "No_License")
        create(:counter_report, press: press.id, session: 6,  noid: 'c',  parent_noid: 'green', institution: 1, created_at: Time.parse("2018-09-11").utc, access_type: "Controlled", turnaway: "No_License")
        create(:counter_report, press: press.id, session: 7,  noid: 'c1', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-09-13").utc, access_type: "Controlled", turnaway: "No_License")
        create(:counter_report, press: press.id, session: 10, noid: 'a',  parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-12-11").utc, access_type: "Controlled", turnaway: "No_License")

        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      context "items" do
        it "has the correct number of items/titles" do
          expect(subject[:items].length).to eq 3
        end

        it "has the correct titles in order" do
          expect(subject[:items][0]["Title"]).to eq 'Blue'
          expect(subject[:items][1]["Title"]).to eq 'Green'
          expect(subject[:items][2]["Title"]).to eq 'Red'
        end

        it "has the 'No_License' metric_type" do
          expect(subject[:items][0]["Metric_Type"]).to eq 'No_License'
        end

        it "has the correct counts" do
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 1
          expect(subject[:items][1]["Reporting_Period_Total"]).to eq 2
          expect(subject[:items][2]["Reporting_Period_Total"]).to eq 1
        end

        it "has the correct monthly counts" do
          expect(subject[:items][0]["Aug-2018"]).to eq 1
          expect(subject[:items][0]["Sep-2018"]).to eq 0
          expect(subject[:items][1]["Aug-2018"]).to eq 0
          expect(subject[:items][1]["Sep-2018"]).to eq 2
          expect(subject[:items][2]["Aug-2018"]).to eq 1
          expect(subject[:items][2]["Sep-2018"]).to eq 0
        end
      end
    end

    context "the full-on pain of a tr_b3 report" do
      # This is this: https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=11711129
      # From that example we want each metric (of 6) for each access_type (of 2) for each book.
      # I don't really understand how a book can be both "Controlled" and then "OA_Gold", but that seems
      # to be what the example is saying. Seems like a bunch of empty rows to me. But there it is. A monstrosity.
      let(:purple) do
        ::SolrDocument.new(id: 'purple',
                           has_model_ssim: ['Monograph'],
                           title_tesim: ['Purple'],
                           publisher_tesim: ["P"],
                           isbn_tesim: ['888'],
                           date_created_tesim: ['1999'])
      end

      let(:yellow) do
        ::SolrDocument.new(id: 'yellow',
                           has_model_ssim: ['Monograph'],
                           title_tesim: ['Yellow'],
                           publisher_tesim: ["Y"],
                           isbn_tesim: ['999'],
                           date_created_tesim: ['2010'])
      end

      let(:params_object) { CounterReporter::ReportParams.new('tr_b3', params) }
      let(:params) do
        {
          press: press.id,
          institution: institution,
          start_date: start_date,
          end_date: end_date
        }
      end
      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-08-01" }
      let(:end_date) { "2018-09-01" }
      let(:institution) { 1 }

      before do
        ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h, purple.to_h, yellow.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, press: press.id, session: 1,  noid: 'a',  parent_noid: 'red',    institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 1,  noid: 'a2', parent_noid: 'red',    institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'b',  parent_noid: 'blue',   institution: 1, created_at: Time.parse("2018-08-02").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 2,  noid: 'p',  parent_noid: 'purple', institution: 1, created_at: Time.parse("2018-08-05").utc, access_type: "OA_Gold")
        create(:counter_report, press: press.id, session: 2,  noid: 'y',  parent_noid: 'yellow', institution: 1, created_at: Time.parse("2018-08-05").utc, access_type: "OA_Gold")
        create(:counter_report, press: press.id, session: 3,  noid: 'y2', parent_noid: 'yellow', institution: 1, created_at: Time.parse("2018-09-02").utc, access_type: "OA_Gold",    request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'c',  parent_noid: 'green',  institution: 1, created_at: Time.parse("2018-09-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 7,  noid: 'c1', parent_noid: 'green',  institution: 1, created_at: Time.parse("2018-09-13").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 10, noid: 'a',  parent_noid: 'red',    institution: 2, created_at: Time.parse("2018-12-11").utc, access_type: "Controlled")

        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      it "has the correct number of items" do
        expect(subject[:items].length).to be 60
      end

      it "has the titles in the correct order" do
        expect(subject[:items][0]["Title"]).to eq "Blue"
        expect(subject[:items][12]["Title"]).to eq "Green"
        expect(subject[:items][24]["Title"]).to eq "Purple"
        expect(subject[:items][36]["Title"]).to eq "Red"
        expect(subject[:items][48]["Title"]).to eq "Yellow"
      end

      it "includes an Access_Type column" do
        expect(subject[:items][0]["Access_Type"]).to eq "Controlled"
        expect(subject[:items][1]["Access_Type"]).to eq "OA_Gold"
      end

      it "has the correct monthly counts" do
        # blue
        expect(subject[:items][0]["Aug-2018"]).to eq 1 # Controlled, Total_Item_Investigations
        expect(subject[:items][2]["Aug-2018"]).to eq 1 # Controlled, Unique_Item_Investigations
        expect(subject[:items][4]["Aug-2018"]).to eq 1 # Controlled, Unique_Title_Investigations
        # green
        expect(subject[:items][12]["Sep-2018"]).to eq 2 # Controlled, Total_Item_Investigations
        expect(subject[:items][14]["Sep-2018"]).to eq 2 # Controlled, Unique_Item_Investigations
        expect(subject[:items][16]["Sep-2018"]).to eq 2 # Controlled, Unique_Title_Investigations
        expect(subject[:items][18]["Sep-2018"]).to eq 1 # Controlled, Total_Item_Requests
        expect(subject[:items][20]["Sep-2018"]).to eq 1 # Controlled, Unique_Item_Requests
        expect(subject[:items][22]["Sep-2018"]).to eq 1 # Controlled, Unique_Title_Requests
        # purple
        expect(subject[:items][25]["Aug-2018"]).to eq 1 # OA_Gold, Total_Item_Investigations
        expect(subject[:items][27]["Aug-2018"]).to eq 1 # OA_Gold, Unique_Item_Investigations
        expect(subject[:items][29]["Aug-2018"]).to eq 1 # OA_Gold, Unique_Title_Investigations
        # red
        expect(subject[:items][36]["Aug-2018"]).to eq 2 # Controlled, Total_Item_Investigations
        expect(subject[:items][38]["Aug-2018"]).to eq 2 # Controlled, Unique_Item_Investigations
        expect(subject[:items][40]["Aug-2018"]).to eq 1 # Controlled, Unique_Title_Investigations
        expect(subject[:items][42]["Aug-2018"]).to eq 1 # Controlled, Total_Item_Requests
        expect(subject[:items][44]["Aug-2018"]).to eq 1 # Controlled, Unique_Item_Requests
        expect(subject[:items][46]["Aug-2018"]).to eq 1 # Controlled, Unique_Title_Requests
        # yellow
        expect(subject[:items][49]["Aug-2018"]).to eq 1 # OA_Gold, Total_Item_Investigations
        expect(subject[:items][49]["Sep-2018"]).to eq 1 # OA_Gold, Total_Item_Investigations
        expect(subject[:items][51]["Aug-2018"]).to eq 1 # OA_Gold, Unique_Item_Investigations
        expect(subject[:items][51]["Sep-2018"]).to eq 1 # OA_Gold, Unique_Item_Investigations
        expect(subject[:items][53]["Aug-2018"]).to eq 1 # OA_Gold, Unique_Title_Investigations
        expect(subject[:items][53]["Sep-2018"]).to eq 1 # OA_Gold, Unique_Title_Investigations
        expect(subject[:items][55]["Aug-2018"]).to eq 0 # OA_Gold, Total_Item_Requests
        expect(subject[:items][55]["Sep-2018"]).to eq 1 # OA_Gold, Total_Item_Requests
        expect(subject[:items][57]["Sep-2018"]).to eq 1 # OA_Gold, Unique_Item_Requests
        expect(subject[:items][59]["Sep-2018"]).to eq 1 # OA_Gold, Unique_Title_Requests
      end
    end
  end
end
