# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Royalty::UsageReport do
  let(:items) do
    [{ "Proprietary_ID": "111111111",
       "Parent_Proprietary_ID": "AAAAAAAAA",
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
       "Section_Type": "Chapter",
       "Reporting_Period_Total": 5,
       "Jan-2019": 0,
       "Feb-2019": 2,
       "Mar-2019": 2,
       "Apr-2019": 0,
       "May-2019": 0,
       "Jun-2019": 1,
     }.with_indifferent_access,
     { "Parent_Proprietary_ID": "AAAAAAAAA",
       "Proprietary_ID": "333333333",
       "Access_Type": "OA_Gold",
       "Section_Type": "",
       "Reporting_Period_Total": 9,
       "Jan-2019": 3,
       "Feb-2019": 3,
       "Mar-2019": 3,
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
      expect(@reports.keys).to eq ["Copyright_A.usage.201901-201906.csv", "Copyright_B.usage.201901-201906.csv", "usage_combined.201901-201906.csv"]
    end
  end

  describe "#update_results" do
    subject { described_class.new("test", "2019-01-01", "2019-07-31").send(:update_results, items) }

    it "changes 'Reporting_Period_Total' label to 'Hits'" do
      expect(subject[0]["Reporting_Period_Total"]).to be nil
      expect(subject[0]["Hits"]).to eq 100
    end

    it "multiplies Chapter hits by 25" do
      expect(subject[0]["Hits"]).to eq 100
      expect(subject[0]["Apr-2019"]).to eq 25
      expect(subject[0]["Jun-2019"]).to eq 75

      expect(subject[1]["Hits"]).to eq 125
      expect(subject[1]["Mar-2019"]).to eq 50
      expect(subject[1]["May-2019"]).to eq 0
      expect(subject[1]["Jun-2019"]).to eq 25

      expect(subject[2]["Hits"]).to eq 9
      expect(subject[2]["Jan-2019"]).to eq 3
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
end
