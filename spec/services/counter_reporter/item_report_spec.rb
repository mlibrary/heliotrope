# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::ItemReport do
  describe "#unique_noids" do
    subject { described_class.new(params_object).unique_noids(results) }

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
      double("params_object", metric_types: ['Total_Item_Investigations'],
                              access_types: ['Controlled'])
    end

    it "has the unqiue noids" do
      expect(subject).to eq ['noid1', 'noid2', 'noid3']
    end
  end

  describe "#unique_parent_noids" do
    subject { described_class.new(params_object).unique_parent_noids(results) }

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
      double("params_object", metric_types: ['Total_Item_Investigations'],
                              access_types: ['Controlled'])
    end

    it "has the unqiue noids" do
      expect(subject).to eq ['parent_noid1', 'parent_noid2']
    end
  end

  describe "#unique_results" do
    subject { described_class.new(params_object).unique_results(results) }

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
      double("params_object", metric_types: ['Total_Item_Investigations'],
                              access_types: ['Controlled'])
    end

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

    let(:red) do
      ::SolrDocument.new(id: 'red',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Red'],
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
                         title_tesim: ['Green'],
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

    context "an ir report" do
      let(:params_object) do
        CounterReporter::ReportParams.new('ir', institution: institution,
                                                start_date: start_date,
                                                end_date: end_date,
                                                metric_type: metric_type,
                                                access_type: access_type)
      end

      let(:institution_name) { double("institution_name", name: "U of Something") }
      let(:start_date) { "2018-01-01" }
      let(:end_date) { "2018-02-01" }
      let(:institution) { 1 }
      let(:access_type) { 'Controlled' }
      let(:metric_type) { 'Total_Item_Requests' }

      before do
        ActiveFedora::SolrService.add([red.to_h, a.to_h, a2.to_h, green.to_h, c.to_h, blue.to_h, b.to_h])
        ActiveFedora::SolrService.commit

        create(:counter_report, session: 1,  noid: 'a', model: 'FileSet', parent_noid: 'red', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 1,  noid: 'a2', model: 'FileSet', parent_noid: 'red', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Forward", section_type: "Chapter")
        create(:counter_report, session: 1,  noid: 'b', model: 'FileSet', parent_noid: 'blue', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Chapter R", section_type: "Chapter")
        create(:counter_report, session: 1,  noid: 'b', model: 'FileSet', parent_noid: 'blue', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Chapter X", section_type: "Chapter")
        create(:counter_report, session: 6,  noid: 'c', model: 'FileSet', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 6,  noid: 'c', model: 'FileSet', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
        create(:counter_report, session: 7,  noid: 'green', model: 'Monograph', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-13").utc, access_type: "Controlled")
        create(:counter_report, session: 10, noid: 'a', model: 'FileSet', parent_noid: 'red', institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)

        allow(Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
      end

      context "items" do
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
    end
  end
end
