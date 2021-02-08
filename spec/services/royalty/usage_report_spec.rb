# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Royalty::UsageReport do
  let(:items) do
    [{ "Proprietary_ID": "111111111",
       "Parent_Proprietary_ID": "AAAAAAAAA",
       "Section_Type": "Chapter",
       "ISBN": "9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)",
       "Publisher": "U of A",
       "Reporting_Period_Total": 2300,
       "Jan-2019": 0,
       "Feb-2019": 0,
       "Mar-2019": 0,
       "Apr-2019": 1000,
       "May-2019": 0,
       "Jun-2019": 1300,
    }.with_indifferent_access,
     { "Proprietary_ID": "222222222",
       "Parent_Proprietary_ID": "BBBBBBBBB",
       "Section_Type": "Chapter",
       "ISBN": "9780813915425 (hardcover), 9780813915432 (paper)",
       "Publisher": "U of B",
       "Reporting_Period_Total": 5,
       "Jan-2019": 0,
       "Feb-2019": 2,
       "Mar-2019": 2,
       "Apr-2019": 0,
       "May-2019": 0,
       "Jun-2019": 1,
     }.with_indifferent_access,
     { "Proprietary_ID": "333333333",
       "Parent_Proprietary_ID": "AAAAAAAAA",
       "Section_Type": "",
       "ISBN": "9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)",
       "Publisher": "U of A",
       "Access_Type": "OA_Gold",
       "Reporting_Period_Total": 9,
       "Jan-2019": 3,
       "Feb-2019": 3,
       "Mar-2019": 3,
       "Apr-2019": 0,
       "May-2019": 0,
       "Jun-2019": 0,
     }.with_indifferent_access,
     { "Proprietary_ID": "333333333",
       "Parent_Proprietary_ID": "AAAAAAAAA",
       "Section_Type": "",
       "ISBN": "9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)",
       "Publisher": "U of A",
       "Access_Type": "Controlled",
       "Reporting_Period_Total": 0,
       "Jan-2019": 0,
       "Feb-2019": 0,
       "Mar-2019": 0,
       "Apr-2019": 0,
       "May-2019": 0,
       "Jun-2019": 0,
     }.with_indifferent_access]
  end

  describe "#report" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-06-30").report }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"],
                       identifier_tesim: ["heb90001.0001.001", "http://hdl.handle.net/2027/heb.31695"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"],
                       identifier_tesim: ["http://hdl.handle.net/2027/heb.sxklj", "heb33333.0001.001"])
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
      expect(@reports.keys).to eq ["Copyright_A.usage.201901-201906.csv", "Copyright_B.usage.201901-201906.csv", "usage_combined.201901-201906.csv"]
      expect(@reports["Copyright_A.usage.201901-201906.csv"][:items].length).to eq 2
      expect(@reports["Copyright_B.usage.201901-201906.csv"][:items].length).to eq 1
      # note that the "Proprietary_ID": "333333333" and "Access_Type": "Controlled" row has
      # been removed by the remove_extra_lines method
      expect(@reports["usage_combined.201901-201906.csv"][:items].length).to eq 3
      # make sure we have the right formatting for larger numbers (commas)
      expect(@reports["usage_combined.201901-201906.csv"][:header][:"Total Hits (All Titles, All Rights Holders)"]).to eq "2,314"
      expect(@reports["usage_combined.201901-201906.csv"][:items][0]["Jun-2019"]).to eq "1,300"
      expect(@reports["Copyright_B.usage.201901-201906.csv"][:items][0]["Parent_ISBN"]).to be nil
      expect(@reports["Copyright_B.usage.201901-201906.csv"][:items][0]["Parent_Print_ISSN"]).to be nil
      expect(@reports["Copyright_B.usage.201901-201906.csv"][:items][0]["Parent_Online_ISSN"]).to be nil
    end
  end

  describe "#report_for_copyholder" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-06-30").report_for_copyholder("Copyright A") }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"],
                       identifier_tesim: ["heb90001.0001.001", "http://hdl.handle.net/2027/heb.31695"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"],
                       identifier_tesim: ["http://hdl.handle.net/2027/heb.sxklj", "heb33333.0001.001"])
    end
    let(:counter_report) { double("counter_report") }
    let(:item_report) { { items: items } }

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
      allow(CounterReporter::ItemReport).to receive(:new).and_return(counter_report)
      allow(counter_report).to receive(:report).and_return(item_report)
    end

    it "returns a report for a single copyright holder" do
      expect(subject[:header][:"Rightsholder Name"]).to eq "Copyright A"
      expect(subject[:header][:"Total Hits"]).to eq "2,309"
      expect(subject[:items].length).to eq 2
      expect(subject[:items][0]["Proprietary_ID"]).to eq "111111111"
      expect(subject[:items][0]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(subject[:items][0]["Hits"]).to eq "2,300"
      expect(subject[:items][0]["Apr-2019"]).to eq "1,000"
      expect(subject[:items][0]["May-2019"]).to eq "0"
      expect(subject[:items][0]["Jun-2019"]).to eq "1,300"
      expect(subject[:items][1]["Proprietary_ID"]).to eq "333333333"
      expect(subject[:items][1]["Parent_Proprietary_ID"]).to eq "AAAAAAAAA"
      expect(subject[:items][1]["Hits"]).to eq "9"
      expect(subject[:items][1]["Jan-2019"]).to eq "3"
      expect(subject[:items][1]["Feb-2019"]).to eq "3"
      expect(subject[:items][1]["Mar-2019"]).to eq "3"
      expect(subject[:items][1]["Jun-2019"]).to eq "0"
    end
  end

  describe "#update_results" do
    subject { described_class.new("test", "2019-01-01", "2019-07-31").send(:update_results, items) }

    it "changes 'Reporting_Period_Total' label to 'Hits'" do
      expect(subject[0]["Reporting_Period_Total"]).to be nil
      expect(subject[0]["Hits"]).to eq 2300
    end

    it "turns OA_Gold to OA" do
      expect(subject[2]["Access_Type"]).to eq "OA"
    end
  end

  describe "#items_by_copyholder" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-07-31").send(:items_by_copyholders, items) }

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

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
    end

    it "has items by copyright holders" do
      expect(subject["Copyright A"][0]["Proprietary_ID"]).to eq "111111111"
      expect(subject["Copyright A"][1]["Proprietary_ID"]).to eq "333333333"
      expect(subject["Copyright B"][0]["Proprietary_ID"]).to eq "222222222"
    end
  end

  describe "#add_hebid" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-07-31").add_hebids(items) }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"],
                       identifier_tesim: ["heb90001.0001.001", "http://hdl.handle.net/2027/heb.31695"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"],
                       identifier_tesim: ["http://hdl.handle.net/2027/heb.sxklj", "heb33333.0001.001"])
    end

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
    end

    it "has the hebid in the correct place (right after the Parent_Proprietary_ID)" do
      expect(subject[0].keys[2]).to eq "hebid"
      expect(subject[0].values[2]).to eq "heb90001.0001.001" # monograph AAAAAAAAA
      expect(subject[1].keys[2]).to eq "hebid"
      expect(subject[1].values[2]).to eq "heb33333.0001.001" # monograph BBBBBBBBB
      expect(subject[2].keys[2]).to eq "hebid"
      expect(subject[2].values[2]).to eq "heb90001.0001.001" # monograph AAAAAAAAA
      expect(subject[3].keys[2]).to eq "hebid"
      expect(subject[3].values[2]).to eq "heb90001.0001.001" # monograph AAAAAAAAA
    end
  end

  describe "#reclassify_isbns" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-07-31").reclassify_isbns(items) }

    let(:press) { create(:press, subdomain: "blue") }

    it "has ISBNs sperated into ebook, hardcover and paper. Replaces the current ISBN field with 3 classified ISBN fields" do
      # monograph AAAAAAAAA
      expect(subject[0].keys[3]).to eq "ebook ISBN"
      expect(subject[0]["ebook ISBN"]).to eq "9780520319196"
      expect(subject[0].keys[4]).to eq "hardcover ISBN"
      expect(subject[0]["hardcover ISBN"]).to eq "9780520047983"
      expect(subject[0].keys[5]).to eq "paper ISBN"
      expect(subject[0]["paper ISBN"]).to eq "9780520319189"
      # monograph BBBBBBBBB
      expect(subject[1].keys[3]).to eq "ebook ISBN"
      expect(subject[1]["ebook ISBN"]).to eq ""
      expect(subject[1].keys[4]).to eq "hardcover ISBN"
      expect(subject[1]["hardcover ISBN"]).to eq "9780813915425"
      expect(subject[1].keys[5]).to eq "paper ISBN"
      expect(subject[1]["paper ISBN"]).to eq "9780813915432"
    end
  end

  describe "#add_copyright_holder_to_combined_report" do
    subject { described_class.new(press.subdomain, "2019-01-01", "2019-07-31").add_copyright_holder_to_combined_report(items) }

    let(:press) { create(:press, subdomain: "blue") }
    let(:mono1) do
      SolrDocument.new(id: "AAAAAAAAA",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright A"],
                       title_tesim: ["A"],
                       identifier_tesim: ["heb90001.0001.001", "http://hdl.handle.net/2027/heb.31695"])
    end

    let(:mono2) do
      SolrDocument.new(id: "BBBBBBBBB",
                       has_model_ssim: ['Monograph'],
                       press_sim: press.subdomain,
                       copyright_holder_tesim: ["Copyright B"],
                       title_tesim: ["B"],
                       identifier_tesim: ["http://hdl.handle.net/2027/heb.sxklj", "heb33333.0001.001"])
    end

    before do
      ActiveFedora::SolrService.add([mono1.to_h, mono2.to_h])
      ActiveFedora::SolrService.commit
    end

    it "has the correct Copyright Holder in the right place, after the Publisher field" do
      expect(subject[0].keys[5]).to eq "Copyright Holder"
      expect(subject[0]["Copyright Holder"]).to eq "Copyright A"
      expect(subject[1].keys[5]).to eq "Copyright Holder"
      expect(subject[1]["Copyright Holder"]).to eq "Copyright B"
    end
  end
end
