# frozen_string_literal: true

require 'rails_helper'

# COUNTER Code of Practice Release 5.0.2 specification.
# https://cop5.projectcounter.org/en/5.0.2/04-reports/04-item-reports.html

RSpec.describe CounterReporter::ItemReport do
  describe "#unique_noids" do
    subject { described_class.new(params_object).unique_noids(results, metric_types, access_types) }

    let(:results) do
      {
        'Jan-2018' => {
          'total_item_investigations' => {
            'controlled' =>  {
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 1'] => 2,
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 2'] => 1,
              ['parent_noid2', 'noid2', nil, nil] => 4,
              ['parent_noid2', 'noid3', nil, nil] => 1
            }
          }
        }
      }
    end

    let(:params_object) do
      double("params_object", metric_types: metric_types,
                              access_types: access_types)
    end
    let(:metric_types) { ['Total_Item_Investigations'] }
    let(:access_types) { ['Controlled'] }

    it "has the unqiue noids" do
      expect(subject).to eq ['noid1', 'noid2', 'noid3']
    end
  end

  describe "#unique_parent_noids" do
    subject { described_class.new(params_object).unique_parent_noids(results, metric_types, access_types) }

    let(:results) do
      {
        'Jan-2018' => {
          'total_item_investigations' => {
            'controlled' =>  {
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 1'] => 2,
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 2'] => 1,
              ['parent_noid2', 'noid2', nil, nil] => 4,
              ['parent_noid2', 'noid3', nil, nil] => 1
            }
          }
        }
      }
    end

    let(:params_object) do
      double("params_object", metric_types: metric_types,
                              access_types: access_types)
    end
    let(:metric_types) { ['Total_Item_Investigations'] }
    let(:access_types) { ['Controlled'] }

    it "has the unqiue noids" do
      expect(subject).to eq ['parent_noid1', 'parent_noid2']
    end
  end

  describe "#unique_results" do
    subject { described_class.new(params_object).unique_results(results, metric_types, access_types) }

    let(:results) do
      {
        'Jan-2018' => {
          'total_item_investigations' => {
            'controlled' =>  {
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 1'] => 2,
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 2'] => 1,
              ['parent_noid2', 'noid2', nil, nil] => 4,
              ['parent_noid2', 'noid3', nil, nil] => 1
            }
          }
        },
        'Feb-2018' => {
          'total_item_investigations' => {
            'controlled' => {
              ['parent_noid3', 'noid4', 'Chapter', 'Chapter Title 3'] => 5,
              ['parent_noid3', 'noid5', nil, nil] => 3,
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 2'] => 1,
              ['parent_noid1', 'noid1', 'Chapter', 'Chapter 999'] => 3
            }
          }
        }
      }
    end

    let(:params_object) do
      double("params_object", metric_types: metric_types,
                              access_types: access_types)
    end
    let(:metric_types) { ['Total_Item_Investigations'] }
    let(:access_types) { ['Controlled'] }

    it "has all unique results" do
      expect(subject).to eq(
        ['parent_noid1', 'noid1', 'Chapter', 'Chapter 999'] => 3,
        ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 1'] => 2,
        ['parent_noid1', 'noid1', 'Chapter', 'Chapter Title 2'] => 2,
        ['parent_noid2', 'noid2', nil, nil] => 4,
        ['parent_noid2', 'noid3', nil, nil] => 1,
        ['parent_noid3', 'noid4', 'Chapter', 'Chapter Title 3'] => 5,
        ['parent_noid3', 'noid5', nil, nil] => 3
      )
    end
  end

  describe "#report" do
    subject { described_class.new(params_object).report }

    let(:press) { create(:press) }
    let(:institution) { instance_double(Greensub::Institution, 'institution', identifier: 1, name: "U of Something", ror_id: 'ror') }

    let(:red) do
      ::SolrDocument.new(id: 'red',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['_Red_'],
                         publisher_tesim: ["R Pub"],
                         isbn_tesim: ['111', '222'],
                         date_created_tesim: ['2000'])
    end
    let(:a) do
      ::SolrDocument.new(id: 'a',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['A'],
                         monograph_id_ssim: ['red'])
    end
    let(:a2) do
      ::SolrDocument.new(id: 'a2',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['A2'],
                         monograph_id_ssim: ['red'])
    end

    let(:green) do
      ::SolrDocument.new(id: 'green',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['__Green__'],
                         publisher_tesim: ["G Pub"],
                         isbn_tesim: ['AAA', 'BBB'],
                         date_created_tesim: ['2000'])
    end
    let(:c) do
      ::SolrDocument.new(id: 'c',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['C'],
                         monograph_id_ssim: ['green'])
    end

    let(:blue) do
      ::SolrDocument.new(id: 'blue',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Blue'],
                         publisher_tesim: ["B Pub"],
                         isbn_tesim: ['ZZZ', 'YYY'],
                         date_created_tesim: ['1999'])
    end
    let(:b) do
      ::SolrDocument.new(id: 'b',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['B'],
                         monograph_id_ssim: ['blue'])
    end

    before { allow(Greensub::Institution).to receive(:find_by).with(identifier: institution.identifier).and_return(institution) }

    context "an ir report" do
      let(:params_object) do
        CounterReporter::ReportParams.new('ir', institution: institution.identifier,
                                                press: press.id,
                                                start_date: start_date,
                                                end_date: end_date,
                                                data_type: data_type,
                                                metric_type: metric_type,
                                                access_type: access_type,
                                                access_method: access_method,
                                                attributes_to_show: %w[Data_Type],
                                                include_parent_details: true,
                                                include_component_details: true)
      end

      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }
      let(:data_type) { 'Book' }
      let(:access_type) { 'Controlled' }
      let(:access_method) { 'Regular' }
      let(:metric_type) { 'Total_Item_Requests' }

      before do
        ActiveFedora::SolrService.add([red.to_h, a.to_h, a2.to_h, green.to_h, c.to_h, blue.to_h, b.to_h])
        ActiveFedora::SolrService.commit

        # Let's have 'c' be an epub, and 'a' be a pdf_ebook
        FeaturedRepresentative.create(file_set_id: 'c', work_id: 'green', kind: 'epub')
        FeaturedRepresentative.create(file_set_id: 'a', work_id: 'red', kind: 'pdf_ebook')

        create(:counter_report, press: press.id, session: 1,  noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a2',    model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Forward", section_type: "Chapter")
        create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Chapter R", section_type: "Chapter")
        create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Chapter X", section_type: "Chapter")
        create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 7,  noid: 'green', model: 'Monograph', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-13").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 10, noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)
      end

      context "items" do
        it "has the correct platform" do
          expect(subject[:items][0]["Platform"]). to eq "Fulcrum/#{press.name}"
        end

        it "has to correct number of items" do
          expect(subject[:items].length).to eq 5
        end

        it "has the correct titles in order" do
          expect(subject[:items][0]["Parent_Title"]).to eq 'Blue'
          expect(subject[:items][1]["Parent_Title"]).to eq 'Blue'
          expect(subject[:items][2]["Parent_Title"]).to eq 'Green'
          expect(subject[:items][3]["Parent_Title"]).to eq 'Red'
          expect(subject[:items][4]["Parent_Title"]).to eq 'Red'

          expect(subject[:items][0]["Item"]).to eq 'B'
          expect(subject[:items][1]["Item"]).to eq 'B'
          expect(subject[:items][2]["Item"]).to eq 'C'
          expect(subject[:items][3]["Item"]).to eq 'A'
          expect(subject[:items][4]["Item"]).to eq 'A2'

          expect(subject[:items][0]["Component_Title"]).to eq 'Chapter R'
          expect(subject[:items][1]["Component_Title"]).to eq 'Chapter X'
          expect(subject[:items][2]["Component_Title"]).to eq ''
          expect(subject[:items][3]["Component_Title"]).to eq ''
          expect(subject[:items][4]["Component_Title"]).to eq 'Forward'

          expect(subject[:items][0]["Data_Type"]).to eq "Book_Segment"
          expect(subject[:items][1]["Data_Type"]).to eq "Book_Segment"
          expect(subject[:items][2]["Data_Type"]).to eq "Book" # epub featured representative
          expect(subject[:items][3]["Data_Type"]).to eq "Book" # pdf_ebook featured_representative
          expect(subject[:items][4]["Data_Type"]).to eq "Book_Segment"

          # I think we want epub, pdf_ebooks and chapters to all point to the "epub" url, not the file_set url
          expect(subject[:items][0]["URI"]).to match(/^http:\/\/test\.host\/epubs\/*/)
          expect(subject[:items][1]["URI"]).to match(/^http:\/\/test\.host\/epubs\/*/)
          expect(subject[:items][2]["URI"]).to match(/^http:\/\/test\.host\/epubs\/*/)
          expect(subject[:items][3]["URI"]).to match(/^http:\/\/test\.host\/epubs\/*/)
          expect(subject[:items][4]["URI"]).to match(/^http:\/\/test\.host\/epubs\/*/)
        end

        it "has the correct counts" do
          expect(subject[:items][0]["Reporting_Period_Total"]).to eq 1
          expect(subject[:items][1]["Reporting_Period_Total"]).to eq 1
          expect(subject[:items][2]["Reporting_Period_Total"]).to eq 2
          expect(subject[:items][3]["Reporting_Period_Total"]).to eq 1
          expect(subject[:items][4]["Reporting_Period_Total"]).to eq 1

          expect(subject[:items][0]["Jan-2018"]).to eq 1
          expect(subject[:items][1]["Jan-2018"]).to eq 1
          expect(subject[:items][2]["Feb-2018"]).to eq 2
          expect(subject[:items][3]["Jan-2018"]).to eq 1
          expect(subject[:items][4]["Jan-2018"]).to eq 1
        end
      end

      context "header" do
        it do
          expect(subject[:header][:Report_Name]).to eq "Item Master Report"
          expect(subject[:header][:Report_ID]).to eq "IR"
          expect(subject[:header][:Release]).to eq "5"
          expect(subject[:header][:Institution_Name]).to eq institution.name
          expect(subject[:header][:Institution_ID]).to eq "ID:#{institution.identifier}; ROR:#{institution.ror_id}"
          expect(subject[:header][:Metric_Types]).to eq "Total_Item_Requests"
          expect(subject[:header][:Report_Filters]).to eq "Platform=#{press.subdomain}; Data_Type=Book; Access_Type=Controlled; Access_Method=Regular"
          expect(subject[:header][:Report_Attributes]).to eq "Attributes_To_Show=Data_Type; Include_Parent_Details=True; Include_Component_Details=True"
          expect(subject[:header][:Exceptions]).to eq ""
          expect(subject[:header][:Reporting_Period]).to eq "Begin_Date=2018-01-01; End_Date=2018-02-28"
          expect(subject[:header][:Created]).to eq Time.zone.today.iso8601
          expect(subject[:header][:Created_By]).to eq "Fulcrum/#{press.name}"
        end
      end
    end

    context "an ir_m1 report" do
      let(:params_object) do
        CounterReporter::ReportParams.new('ir_m1', institution: institution.identifier,
                                          press: press.id,
                                          start_date: start_date,
                                          end_date: end_date,
                                          attributes_to_show: %w[Access_Type],
                                          include_parent_details: true,
                                          include_component_details: true)
      end

      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }

      let(:a) do
        ::SolrDocument.new(id: 'a',
                           has_model_ssim: ['FileSet'],
                           title_tesim: ['A'],
                           monograph_id_ssim: ['red'],
                           mime_type_ssi: 'image/jpg')
      end
      let(:b) do
        ::SolrDocument.new(id: 'b',
                           has_model_ssim: ['FileSet'],
                           title_tesim: ['B'],
                           monograph_id_ssim: ['blue'],
                           mime_type_ssi: 'video/mp4')
      end
      let(:c) do
        ::SolrDocument.new(id: 'c',
                           has_model_ssim: ['FileSet'],
                           title_tesim: ['C'],
                           monograph_id_ssim: ['green'],
                           mime_type_ssi: 'audio/mp3')
      end

      before do
        ActiveFedora::SolrService.add([red.to_h, a.to_h, a2.to_h, green.to_h, c.to_h, blue.to_h, b.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, press: press.id, session: 1,  noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'a2',    model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Forward", section_type: "Chapter")
        create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, press: press.id, session: 7,  noid: 'green', model: 'Monograph', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-13").utc, access_type: "Controlled")
        create(:counter_report, press: press.id, session: 10, noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)
      end

      it "has to correct number of items" do
        expect(subject[:items].length).to eq 6
      end

      it "has the correct titles in order" do
        expect(subject[:items][0]["Parent_Title"]).to eq 'Blue'
        expect(subject[:items][1]["Parent_Title"]).to eq 'Blue'
        expect(subject[:items][2]["Parent_Title"]).to eq 'Green'
        expect(subject[:items][3]["Parent_Title"]).to eq 'Green'
        expect(subject[:items][4]["Parent_Title"]).to eq 'Red'
        expect(subject[:items][5]["Parent_Title"]).to eq 'Red'
      end

      it 'has both OA_Gold and Controlled' do
        expect(subject[:items][0]["Access_Type"]).to eq 'OA_Gold'
        expect(subject[:items][1]["Access_Type"]).to eq 'Controlled'
        expect(subject[:items][2]["Access_Type"]).to eq 'OA_Gold'
        expect(subject[:items][3]["Access_Type"]).to eq 'Controlled'
        expect(subject[:items][4]["Access_Type"]).to eq 'OA_Gold'
        expect(subject[:items][5]["Access_Type"]).to eq 'Controlled'
      end

      it 'has the correct metric type' do
        expect(subject[:items][0]["Metric_Type"]).to eq 'Total_Item_Requests'
      end

      it 'has the correct counts' do
        expect(subject[:items][0]["Reporting_Period_Total"]).to eq 0
        expect(subject[:items][1]["Reporting_Period_Total"]).to eq 2
        expect(subject[:items][2]["Reporting_Period_Total"]).to eq 0
        expect(subject[:items][3]["Reporting_Period_Total"]).to eq 2
        expect(subject[:items][4]["Reporting_Period_Total"]).to eq 0
        expect(subject[:items][5]["Reporting_Period_Total"]).to eq 1

        expect(subject[:items][1]["Jan-2018"]).to eq 2
        expect(subject[:items][3]["Feb-2018"]).to eq 2
        expect(subject[:items][5]["Jan-2018"]).to eq 1
      end
    end
  end
end
