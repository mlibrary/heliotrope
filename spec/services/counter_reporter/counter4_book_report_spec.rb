# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReporter::Counter4BookReport do
  describe "#results_by_month" do
    subject { described_class.new(params_object).results_by_month }

    let(:params_object) do
      double("params_object", press: 1,
                              institution: '*',
                              access_types: ['Controlled'],
                              start_date: Date.parse("2018-01-01"),
                              end_date: Date.parse("2018-02-01"))
    end

    before do
      create(:counter_report, press: 1, session: 1,  noid: 'a', model: 'FileSet', parent_noid: 'aaa', institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: 1, session: 1,  noid: 'b', model: 'FileSet', parent_noid: 'bbb', institution: 2, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: 1, session: 2,  noid: 'c', model: 'FileSet', parent_noid: 'ccc', institution: 3, created_at: Time.parse("2018-02-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: 1, session: 3,  noid: 'd', model: 'FileSet', parent_noid: 'ccc', institution: 4, created_at: Time.parse("2018-02-02").utc, access_type: "Controlled", request: 1)
    end

    it do
      expect(subject).to eq("Jan-2018" => {
                              ["aaa", "a"] => 1,
                              ["bbb", "b"] => 1
                            },
                            "Feb-2018" => {
                              ["ccc", "c"] => 1,
                              ["ccc", "d"] => 1
                            })
    end
  end

  describe "#unique_noids" do
    subject { described_class.new(params_object).unique_noids(results) }

    let(:params_object) { double(:params_object) }
    let(:results) do
      {
        "Jan-2018" => {
          ["parent_noid1", "a"] => 1,
          ["parent_noid1", "b"] => 1
        },
        "Feb-2018" => {
          ["parent_noid2", "c"] => 1,
          ["parent_noid2", "d"] => 1
        }
      }
    end

    it 'has the unique noids' do
      expect(subject).to eq ['a', 'b', 'c', 'd']
    end
  end

  describe '#unique_parent_noids' do
    subject { described_class.new(params_object).unique_parent_noids(results) }

    let(:params_object) { double(:params_object) }
    let(:results) do
      {
        "Jan-2018" => {
          ["parent_noid1", "a"] => 1,
          ["parent_noid1", "b"] => 1
        },
        "Feb-2018" => {
          ["parent_noid2", "c"] => 1,
          ["parent_noid2", "d"] => 1
        }
      }
    end

    it 'has unique parent noids' do
      expect(subject).to eq ['parent_noid1', 'parent_noid2']
    end
  end

  describe '#remove_mulitmedia' do
    subject { described_class.new(params_object).remove_multimedia(results, file_sets) }

    let(:params_object) { double(:params_object) }
    let(:results) do
      {
        "Jan-2018" => {
          ["parent_noid1", "a"] => 1,
          ["parent_noid1", "b"] => 1
        },
        "Feb-2018" => {
          ["parent_noid2", "c"] => 1,
          ["parent_noid3", "d"] => 1
        }
      }
    end
    let(:a) { double("presenter", multimedia?: false) }
    let(:b) { double("presenter", multimedia?: true) }
    let(:c) { double("presenter", multimedia?: false) }
    let(:d) { double("presenter", multimedia?: false) }
    let(:file_sets) { { 'a' => a, 'b' => b, 'c' => c, 'd' => d } }

    it "has no multimedia file_sets" do
      expect(subject).to eq("Jan-2018" => {
                              ["parent_noid1", "a"] => 1
                            },
                            "Feb-2018" => {
                              ["parent_noid2", "c"] => 1,
                              ["parent_noid3", "d"] => 1
                            })
    end
  end

  describe '#results_by_parent' do
    subject { described_class.new(params_object).results_by_parent(results) }

    let(:params_object) { double(:params_object) }
    let(:results) do
      {
        "Jan-2018" => {
          ["aaa", "a"] => 2,
          ["bbb", "b"] => 3
        },
        "Feb-2018" => {
          ["ccc", "c"] => 4,
          ["ccc", "d"] => 5
        }
      }
    end

    it "has correct counts by parent noid" do
      expect(subject).to eq("Jan-2018" => {
                              "aaa" => 2,
                              "bbb" => 3
                            },
                            "Feb-2018" => {
                              "ccc" => 9
                            })
    end
  end

  describe '#report' do
    subject { described_class.new(params_object).report }

    let(:press) { create(:press) }
    let(:params_object) do
      CounterReporter::ReportParams.new('counter4_br2', press: press.id,
                                                        institution: institution,
                                                        start_date: start_date,
                                                        end_date: end_date)
    end
    let(:institution_name) { double("institution_name", identifier: 1, name: "U of Something") }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-02-28" }
    let(:institution) { 1 }

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
                         monograph_id_ssim: ['red'],
                         mime_type_ssi: 'image/jpg') # multimedia
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

    before do
      ActiveFedora::SolrService.add([red.to_h, a.to_h, a2.to_h, green.to_h, c.to_h, blue.to_h, b.to_h])
      ActiveFedora::SolrService.commit

      create(:counter_report, press: press.id, session: 1,  noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1, section: "Forward", section_type: "Chapter")
      # skip multimedia
      create(:counter_report, press: press.id, session: 1,  noid: 'a2',    model: 'FileSet',   parent_noid: 'red',   institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: 1,  noid: 'b',     model: 'FileSet',   parent_noid: 'blue',  institution: 1, created_at: Time.parse("2018-01-02").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: 6,  noid: 'c',     model: 'FileSet',   parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-11").utc, access_type: "Controlled", request: 1)
      # skip monograph investigation
      create(:counter_report, press: press.id, session: 7,  noid: 'green', model: 'Monograph', parent_noid: 'green', institution: 1, created_at: Time.parse("2018-02-13").utc, access_type: "Controlled")
      # skip wrong institution, out of date range
      create(:counter_report, press: press.id, session: 10, noid: 'a',     model: 'FileSet',   parent_noid: 'red',   institution: 2, created_at: Time.parse("2018-11-11").utc, access_type: "Controlled", request: 1)

      allow(Greensub::Institution).to receive(:where).with(identifier: institution).and_return([institution_name])
    end

    it "has the correct header" do
      expect(subject[:header][0].length).to eq 9
      expect(subject[:header][0][0]).to eq "Book Report 2 (R2)"
      expect(subject[:header][0][1]).to eq "Number of Successful Section Requests by Month and Title"
      expect(subject[:header][1][0]).to eq institution_name.name
      expect(subject[:header][1][1]).to eq "Section Type:"
      expect(subject[:header][2][0]).to eq ""
      expect(subject[:header][2][1]).to eq "Chapter, EReader"
    end

    it "has the correct totals row" do
      expect(subject[:items][0].length).to eq 9
      expect(subject[:items][0][0]).to eq "Total for all titles"
      expect(subject[:items][0][6]).to eq 5 # total
      expect(subject[:items][0][7]).to eq 3 # total Jan
      expect(subject[:items][0][8]).to eq 2 # total Feb
    end

    it "has the correct title counts" do
      expect(subject[:items][1].length).to eq 9
      expect(subject[:items][1][0]).to eq "Blue"
      expect(subject[:items][1][6]).to eq 2
      expect(subject[:items][1][7]).to eq 2 # Jan
      expect(subject[:items][1][8]).to eq 0 # Feb
      expect(subject[:items][2][0]).to eq "Green"
      expect(subject[:items][2][6]).to eq 2
      expect(subject[:items][2][7]).to eq 0 # Jan
      expect(subject[:items][2][8]).to eq 2 # Feb
      expect(subject[:items][3][0]).to eq "Red"
      expect(subject[:items][3][6]).to eq 1
      expect(subject[:items][3][7]).to eq 1 # Jan
      expect(subject[:items][3][8]).to eq 0 # Feb
    end
  end
end
