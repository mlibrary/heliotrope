# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Royalty::CalculationReport do
  describe "#report" do
    let(:items) do
       [{ "Proprietary_ID": "111111111",
          "Parent_Proprietary_ID": "AAAAAAAAA",
          "Authors": "Some One",
          "Parent_Title": "A",
          "DOI": "http://doi.org/a",
          "Parent_DOI": "http:/doi.org/parent",
          "ISBN": "9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)",
          "Parent_ISBN": "",
          "Publisher": "Flub",
          "Section_Type": "Chapter",
          "Reporting_Period_Total": 1001,
          "Jan-2019": 0,
          "Feb-2019": 0,
          "Mar-2019": 0,
          "Apr-2019": 250,
          "May-2019": 0,
          "Jun-2019": 751,
       }.with_indifferent_access,
        { "Parent_Proprietary_ID": "BBBBBBBBB",
          "Proprietary_ID": "222222222",
          "Authors": "No One",
          "Parent_Title": "B",
          "DOI": "http://doi.org/b",
          "Parent_DOI": "http:/doi.org/parent",
          "ISBN": "9780813915425 (hardcover), 9780813915432 (paper)",
          "Parent_ISBN": "",
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
          "DOI": "http://doi.org/a",
          "Parent_DOI": "http:/doi.org/parent",
          "ISBN": "9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)",
          "Parent_ISBN": "",
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
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-06-30", 1000.00).report }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"],
                       identifier_tesim: ["heb_id: heb90001.0001.001", "http://hdl.handle.net/2027/heb.31695"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"],
                       identifier_tesim: ["http://hdl.handle.net/2027/heb.sxklj", "heb_id: heb33333.0001.001"])
    end
    let(:counter_report) { double("counter_report") }
    let(:item_report) { { items: items } }

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
      allow(CounterReporter::ItemReport).to receive(:new).and_return(counter_report)
      allow(counter_report).to receive(:report).and_return(item_report)
    end

    it "creates the reports" do
      @reports = subject

      expect(@reports.keys).to eq ["Copyright_A.calc.201901-201906.csv", "Copyright_B.calc.201901-201906.csv", "calc_combined.201901-201906.csv"]

      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Total Royalties Shared (All Rights Holders)"]).to eq "1,000.00"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Total Hits (Non-OA Titles, All Rights Holders)"]).to eq "1,016"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Rightsholder Hits"]).to eq "1,011"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:header][:"Rightsholder Royalties"]).to eq "995.08"

      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Total Title Hits"]).to eq "1,011"

      expect(@reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Parent_Proprietary_ID"]).to eq "BBBBBBBBB"
      expect(@reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Total Title Hits"]).to eq "5"
      expect(@reports["Copyright_B.calc.201901-201906.csv"][:header][:"Rightsholder Hits"]).to eq "5"
      expect(@reports["Copyright_B.calc.201901-201906.csv"][:header][:"Rightsholder Royalties"]).to eq "4.92"


      expect(@reports["Copyright_A.calc.201901-201906.csv"][:items][0]["Royalty Earning"].to_f +
             @reports["Copyright_B.calc.201901-201906.csv"][:items][0]["Royalty Earning"].to_f).to eq 1000.0

      # HELIO-3572 the calc combined has no "Report" header
      expect(@reports["calc_combined.201901-201906.csv"][:header]).to eq Hash.new
      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["hebid"]).to eq "heb90001.0001.001"
      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["Copyright Holder"]).to eq "Copyright A"
      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["ebook ISBN"]).to eq "9780520319196"
      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["hardcover ISBN"]).to eq "9780520047983"
      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["paper ISBN"]).to eq "9780520319189"
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["hebid"]).to eq "heb33333.0001.001"
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["Copyright Holder"]).to eq "Copyright B"
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["ebook ISBN"]).to eq ""
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["hardcover ISBN"]).to eq "9780813915425"
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["paper ISBN"]).to eq "9780813915432"

      expect(@reports["calc_combined.201901-201906.csv"][:items][0]["Total Title Hits"]).to eq "1,011"
      expect(@reports["calc_combined.201901-201906.csv"][:items][1]["Total Title Hits"]).to eq "5"
    end
  end

  describe "different case copyright holders have seperate reports" do
    # See HELIO-3361
    let(:items) do
      [{ "Parent_Proprietary_ID": "AAAAAAAAA",
         "Proprietary_ID": "111111111",
         "Authors": "Some One",
         "Parent_Title": "A",
         "DOI": "http://doi.org/a",
         "ISBN": "9780231503709 (E-Book)",
         "Publisher": "Flub",
         "Section_Type": "Chapter",
         "Reporting_Period_Total": 1,
         "Jan-2019": 1
       }.with_indifferent_access,
       { "Parent_Proprietary_ID": "BBBBBBBBB",
         "Proprietary_ID": "222222222",
         "Authors": "No One",
         "Parent_Title": "B",
         "DOI": "http://doi.org/b",
         "ISBN": "9780292713420, 029271341X, 0292713428, 9780292713413",
         "Publisher": "Derp",
         "Section_Type": "Chapter",
         "Reporting_Period_Total": 5,
         "Jan-2019": 5
       }.with_indifferent_access,
       { "Parent_Proprietary_ID": "AAAAAAAAA",
         "Proprietary_ID": "333333333",
         "Authors": "Some One",
         "Parent_Title": "A",
         "DOI": "http://doi.org/a",
         "ISBN": "9780231503709 (E-Book)",
         "Publisher": "Flub",
         "Section_Type": "",
         "Reporting_Period_Total": 1,
         "Jan-2019": 1
       }.with_indifferent_access]
    end

    subject { described_class.new(press.subdomain, "2019-01-01", "2019-02-28", 1000.00).report }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Assumed rights"], # note case "rights"
                       title_tesim: ["A"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Assumed Rights"], # note case "Rights"
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

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
      allow(CounterReporter::ItemReport).to receive(:new).and_return(counter_report)
      allow(counter_report).to receive(:report).and_return(item_report)
    end

    it "sends the reports" do
      allow(Net::FTP).to receive(:open).and_return(ftp)
      allow(ftp).to receive(:mkdir).with("Library PTG Box/HEB/HEB Royalty Reports/2019-01_to_2019-02").and_return(true)

      @reports = subject

      expect(@reports.keys).to eq ["Assumed_rights.calc.201901-201902.csv", "Assumed_Rights.calc.201901-201902.csv", "calc_combined.201901-201902.csv"]

      expect(@reports["Assumed_rights.calc.201901-201902.csv"][:header][:"Rightsholder Name"]).to eq "Assumed rights"
      expect(@reports["Assumed_Rights.calc.201901-201902.csv"][:header][:"Rightsholder Name"]).to eq "Assumed Rights"

      # OK. The specs pass. The reports are fine. I think that Box is versioning these files and not respecting their case.
      # I don't think there's anything that can be done about that in heliotrope.
      # Jeremy's got a processes to check correctness of reports out of Box. If the numbers are off, I guess
      # we'll just have to figure it out when that happens (only twice a year, so, meh)
      # See HELIO-3361 for more info.
    end
  end

  describe "#by_monograph" do
    let(:items) do
       [{ "Proprietary_ID": "111111111",
          "Parent_Proprietary_ID": "AAAAAAAAA",
          "Authors": "Some One",
          "Parent_Title": "A",
          "DOI": "http://doi.org/a",
          "Parent_DOI": "http://doi.org/parent",
          "ISBN": "9780231503709 (E-Book)",
          "Parent_ISBN": "",
          "Publisher": "Flub",
          "Section_Type": "Chapter",
          "Hits": 1001,
          "Jan-2019": 0,
          "Feb-2019": 0,
          "Mar-2019": 0,
          "Apr-2019": 250,
          "May-2019": 0,
          "Jun-2019": 751,
       }.with_indifferent_access,
        { "Parent_Proprietary_ID": "BBBBBBBBB",
          "Proprietary_ID": "222222222",
          "Authors": "No One",
          "Parent_Title": "B",
          "DOI": "http://doi.org/b",
          "Parent_DOI": "http://doi.org/parent",
          "ISBN": "9780292713420, 029271341X, 0292713428, 9780292713413",
          "Parent_ISBN": "",
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
          "DOI": "http://doi.org/a",
          "Parent_DOI": "http://doi.org/parent",
          "ISBN": "9780231503709 (E-Book)",
          "Parent_ISBN": "",
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

    subject { described_class.new("test", "2019-01-01", "2019-07-31", "1750").send(:by_monographs, items) }

    it "returns a flatten/condensed list of monographs (not items) but with correct hit counts" do
      expect(subject.length).to be 2

      expect(subject[0]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(subject[0]["Title"]).to eq "A"
      expect(subject[0]["Authors"]).to eq "Some One"
      expect(subject[0]["Publisher"]).to eq "Flub"
      expect(subject[0]["DOI"]).to eq "http://doi.org/parent"
      expect(subject[0]["ISBN"]).to eq "9780231503709 (E-Book)"
      expect(subject[0]["Hits"]).to be 1011
      expect(subject[0]["Royalty Earning"]).to eq 0.00
      expect(subject[0]["Jan-2019"]).to be 3
      expect(subject[0]["Feb-2019"]).to be 3
      expect(subject[0]["Mar-2019"]).to be 3
      expect(subject[0]["Apr-2019"]).to be 251
      expect(subject[0]["May-2019"]).to be 0
      expect(subject[0]["Jun-2019"]).to be 751

      expect(subject[1]["Parent_Proprietary_ID"]).to eq "BBBBBBBBB"
      expect(subject[1]["Title"]).to eq "B"
      expect(subject[1]["Publisher"]).to eq "Derp"
      expect(subject[1]["Authors"]).to eq "No One"
      expect(subject[1]["DOI"]).to eq "http://doi.org/parent"
      expect(subject[1]["ISBN"]).to eq "9780292713420, 029271341X, 0292713428, 9780292713413"
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
      expect(subject).to eq [{ "Hits" => 1, "Royalty Earning" => 1 }, { "Hits" => 1, "Royalty Earning" => 1 }]
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
