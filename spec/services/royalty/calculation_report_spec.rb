# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Royalty::CalculationReport do
  describe "#report" do
    let(:items) do
       [{ "Proprietary_ID": "111111111",
          "Parent_Proprietary_ID": "AAAAAAAAA",
          "Authors": "Some One",
          "Parent_Title": "A",
          "Parent_DOI": "http://doi.org/a",
          "Publisher": "Flub",
          "Section_Type": "Chapter",
          "Reporting_Period_Total": 4,
          "Jan-2019": 0,
          "Feb-2019": 0,
          "Mar-2019": 0,
          "Apr-2019": 1,
          "May-2019": 0,
          "Jun-2019": 3,
       }.with_indifferent_access,
        { "Parent_Proprietary_ID": "BBBBBBBBB",
          "Proprietary_ID": "222222222",
          "Authors": "No One",
          "Parent_Title": "B",
          "Parent_DOI": "http://doi.org/b",
          "Publisher": "Derp",
          "Section_Type": "Chapter",
          "Reporting_Period_Total": 5,
          "Jan-2019": 0,
          "Feb-2019": 2,
          "Mar-2019": 2,
          "Apr-2019": 0,
          "May-2019": 0,
          "Jun-2019": 1
        }.with_indifferent_access,
        { "Parent_Proprietary_ID": "AAAAAAAAA",
          "Proprietary_ID": "333333333",
          "Authors": "Some One",
          "Parent_Title": "A",
          "Parent_DOI": "http://doi.org/a",
          "Publisher": "Flub",
          "Section_Type": "",
          "Reporting_Period_Total": 10,
          "Jan-2019": 3,
          "Feb-2019": 3,
          "Mar-2019": 3,
          "Apr-2019": 1,
          "May-2019": 0,
          "Jun-2019": 0,
        }.with_indifferent_access]
     end
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-06-30", 100.00).report }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"])
    end
    let(:counter_report) { double("counter_report") }
    let(:item_report) { { items: items } }
    let(:ftp) do
      instance_double(Net::FTP,
                      "ftp",
                      mkdir: true,
                      chdir: true,
                      putbinaryfile: true,
                      close: true)
    end

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
      allow(CounterReporter::ItemReport).to receive(:new).and_return(counter_report)
      allow(counter_report).to receive(:report).and_return(item_report)
    end

    it "sends the reports" do
      allow(Net::FTP).to receive(:open).and_return(ftp)
      allow(ftp).to receive(:mkdir).with("Library PTG Box/HEB/HEB Royalty Reports/2019-01_to_2019-06").and_return(true)

      @reports = subject

      expect(@reports.keys).to eq ["Copyright_A.calc.201901-201906.csv", "Copyright_B.calc.201901-201906.csv"]

      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Total Royalties Shared (All Rights Holders)"]).to eq "100.00"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Total Hits (All Rights Holders)"]).to eq "235"

      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Hits"]).to eq 110

      expect(@reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Parent_Proprietary_ID"]).to eq "BBBBBBBBB"
      expect(@reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Hits"]).to eq 125
      # 46.81 + 53.19
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Royalty Earning"].to_f +
             @reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Royalty Earning"].to_f).to eq 100.0
    end
  end

  describe "#by_monograph" do
    let(:items) do
       [{ "Proprietary_ID": "111111111",
          "Parent_Proprietary_ID": "AAAAAAAAA",
          "Authors": "Some One",
          "Parent_Title": "A",
          "Parent_DOI": "http://doi.org/a",
          "Publisher": "Flub",
          "Section_Type": "Chapter",
          "Hits": 100,
          "Jan-2019": 0,
          "Feb-2019": 0,
          "Mar-2019": 0,
          "Apr-2019": 25,
          "May-2019": 0,
          "Jun-2019": 75,
       }.with_indifferent_access,
        { "Parent_Proprietary_ID": "BBBBBBBBB",
          "Proprietary_ID": "222222222",
          "Authors": "No One",
          "Parent_Title": "B",
          "Parent_DOI": "http://doi.org/b",
          "Publisher": "Derp",
          "Section_Type": "Chapter",
          "Hits": 125,
          "Jan-2019": 0,
          "Feb-2019": 50,
          "Mar-2019": 50,
          "Apr-2019": 0,
          "May-2019": 0,
          "Jun-2019": 25
        }.with_indifferent_access,
        { "Parent_Proprietary_ID": "AAAAAAAAA",
          "Proprietary_ID": "333333333",
          "Authors": "Some One",
          "Parent_Title": "A",
          "Parent_DOI": "http://doi.org/a",
          "Publisher": "Flub",
          "Section_Type": "",
          "Hits": 10,
          "Jan-2019": 3,
          "Feb-2019": 3,
          "Mar-2019": 3,
          "Apr-2019": 1,
          "May-2019": 0,
          "Jun-2019": 0,
        }.with_indifferent_access]
     end

    subject { described_class.new("test", "2019-01-01", "2019-07-31", "1.75").send(:by_monographs, items) }

    it "returns a flatten/condensed list of monographs (not items) but with correct hit counts" do
      expect(subject.length).to be 2

      expect(subject[0]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(subject[0]["Title"]).to eq "A"
      expect(subject[0]["Authors"]).to eq "Some One"
      expect(subject[0]["Publisher"]).to eq "Flub"
      expect(subject[0]["DOI"]).to eq "http://doi.org/a"
      expect(subject[0]["Hits"]).to be 110
      expect(subject[0]["Royalty Earning"]).to eq 0.00
      expect(subject[0]["Jan-2019"]).to be 3
      expect(subject[0]["Feb-2019"]).to be 3
      expect(subject[0]["Mar-2019"]).to be 3
      expect(subject[0]["Apr-2019"]).to be 26
      expect(subject[0]["May-2019"]).to be 0
      expect(subject[0]["Jun-2019"]).to be 75

      expect(subject[1]["Parent_Proprietary_ID"]).to eq "BBBBBBBBB"
      expect(subject[1]["Title"]).to eq "B"
      expect(subject[1]["Publisher"]).to eq "Derp"
      expect(subject[1]["Authors"]).to eq "No One"
      expect(subject[1]["DOI"]).to eq "http://doi.org/b"
      expect(subject[1]["Hits"]).to be 125
      expect(subject[0]["Royalty Earning"]).to eq 0.00
      expect(subject[1]["Jan-2019"]).to be 0
      expect(subject[1]["Feb-2019"]).to be 50
      expect(subject[1]["Mar-2019"]).to be 50
      expect(subject[1]["Apr-2019"]).to be 0
      expect(subject[1]["May-2019"]).to be 0
      expect(subject[1]["Jun-2019"]).to be 25
    end
  end

  describe "#calculate_royalty" do
    subject { described_class.new("test", "2019-07-01", "2019-12-31", 2.00).send(:calculate_royalty, items) }

    let(:total_royalties) { 2.00 }
    let(:items) do
      [
        {
          "Hits": 1,
          "Royalty Earning": 0
        }.with_indifferent_access,
        {
          "Hits": 1,
          "Royalty Earning": 0
        }.with_indifferent_access
      ]
    end

    it "calculates royalties" do
      expect(subject).to eq [{ "Hits"=>1, "Royalty Earning"=> 1 }, { "Hits"=>1, "Royalty Earning"=> 1 }]
    end
  end


  describe "#total_royalties_all_rightsholders(items)" do
    subject { described_class.new("test", "2019-01-01", "2019-07-31", "0.00").send(:total_royalties_all_rightsholders, items) }

    let(:items) do
      [
        {
          "Royalty Earning": 1.25
        }.with_indifferent_access,
        {
          "Royalty Earning": 2.50
        }.with_indifferent_access,
        {
          "Royalty Earning": 5.01
        }.with_indifferent_access
      ]
    end

    it "calculates the 'total royalties for all rightsholders'" do
      expect(subject).to eq 8.76
    end
  end

  describe "#format_royalty" do
    subject { described_class.new("test", "2019-01-01", "2019-07-31", 1000.00).send(:format_royalty, items) }

    let(:items) do
      [
        {
          "Royalty Earning": 1000
        }.with_indifferent_access
      ]
    end

    it "formats to a currency, correctly" do
      expect(subject[0]["Royalty Earning"]).to eq "1,000.00"
    end
  end
end
