# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecurringUsageReportJob, type: :job do
  context "with a full test environment" do
    let(:press) { create(:press, subdomain: "barpublishing") }
    let(:institution1) { create(:institution, identifier: 1, name: "U of A") }
    let(:institution2) { create(:institution, identifier: 2, name: "U of B") }
    let(:product) { create(:product, identifier: "something", group_key: "bar") }
    let(:red) do
      ::SolrDocument.new(id: 'red',
                        has_model_ssim: ['Monograph'],
                        title_tesim: ['_Red_'],
                        creator_tesim: ['Red Author'],
                        doi_ssim: ["doi.org/red_book"],
                        date_created_tesim: ['2000'])
    end
    let(:a) do
      ::SolrDocument.new(id: 'a',
                        has_model_ssim: ['FileSet'],
                        title_tesim: ['A'],
                        doi_ssim: ["doi.org/a_file_set"],
                        monograph_id_ssim: ['red'])
    end
    let(:blue) do
      ::SolrDocument.new(id: 'blue',
                        has_model_ssim: ['Monograph'],
                        title_tesim: ['Blue'],
                        doi_ssim: ["doi.org/blue_book"],
                        creator_tesim: ['Blue Author'],
                        date_created_tesim: ['1999'])
    end
    let(:b) do
      ::SolrDocument.new(id: 'b',
                        has_model_ssim: ['FileSet'],
                        title_tesim: ['B'],
                        doi_ssim: ["doi.org/b_file_set"],
                        monograph_id_ssim: ['blue'])
    end
    let(:green) do
      ::SolrDocument.new(id: 'green',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Green Title'],
                         creator_tesim: ['Green Author'],
                         doi_ssim: ["doi.org/green_book"],
                         date_created_tesim: ['2001'],
                         open_access_tesim: ["yes"])
    end
    let(:c) do
      ::SolrDocument.new(id: 'c',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['C'],
                         creator_tesim: ['C FileSet Author'],
                         doi_ssim: ["doi.org/c_file_set"],
                         monograph_id_ssim: ['green'])
    end

    before do
      ActiveFedora::SolrService.add([red.to_h, a.to_h, blue.to_h, b.to_h, green.to_h, c.to_h])
      ActiveFedora::SolrService.commit
      create(:full_license, licensee: institution1, product: product)
      create(:full_license, licensee: institution2, product: product)
      create(:counter_report, press: press.id, session: 1,  noid: 'a', model: 'FileSet', parent_noid: 'red', institution: 1, created_at: Time.parse("2023-03-29").utc, access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: 1,  noid: 'c', model: 'FileSet', parent_noid: 'green', institution: 1, created_at: Time.parse("2023-03-29").utc, access_type: "OA_Gold", request: 1, section: "Chapter Green", section_type: "Chapter")
      create(:counter_report, press: press.id, session: 2,  noid: 'b', model: 'FileSet', parent_noid: 'blue', institution: 2, created_at: Time.parse("2023-03-30").utc, access_type: "Controlled", request: 1, section: "Chapter R", section_type: "Chapter")
    end

    describe "#perform" do
      context "with Settings.recurring_usage_reports" do
        let(:mailer) { double("mailer", deliver_now: true) }
        let(:mock_zip) { double('mock_zip') }
        let(:to) { ["test@email.com"] }

        before do
          allow(RecurringUsageReportMailer).to receive(:send_report).with(to, "2023-03-25", "2023-03-31", mock_zip).and_return(mailer)
          allow_any_instance_of(described_class).to receive(:zipup).and_return(mock_zip)
        end

        # Mocked to the point of almost being useless, but it shows nothing throws errors and the mailer is called
        it "calls the mailer with the correct parameters" do
          travel_to("2023-04-01") do
            described_class.perform_now

            expect(RecurringUsageReportMailer).to have_received(:send_report).with(to, "2023-03-25", "2023-03-31", mock_zip)
          end
        end
      end
    end

    describe "#zipup" do
      let(:reports) do
        {
          "U_of_A_2023-04-01.csv" => "An item report with limited fields",
          "U_of_B_2023-04-01.csv" => "Another item report with limited fields",
          "Total_Items_All_Institutions_2023-04-01.csv" => "An institution report"
        }
      end

      before { allow_any_instance_of(described_class).to receive(:today).and_return("2023-04-01") }
      after { File.unlink(Rails.root.join("tmp", "recurring_reports_2023-04-01_zip")) }

      it "returns a zipped archive containing reports" do
        Zip::File.open(described_class.new.zipup(reports)) do |zip|
          expect(zip.entries[0].name).to eq "U_of_A_2023-04-01.csv"
          expect(zip.entries[0].get_input_stream.read).to eq "An item report with limited fields"
          expect(zip.entries[1].name).to eq "U_of_B_2023-04-01.csv"
          expect(zip.entries[1].get_input_stream.read).to eq "Another item report with limited fields"
          expect(zip.entries[2].name).to eq "Total_Items_All_Institutions_2023-04-01.csv"
          expect(zip.entries[2].get_input_stream.read).to eq "An institution report"
        end
      end
    end

    describe "#institution_requests_report" do
      it "creates the correct report" do
        travel_to("2023-04-01") do
          report_time = RecurringUsageReport::ReportTime.from_interval("last_week")
          name, report = described_class.new.institution_requests_report(report_time, product.group_key, press.subdomain)

          expect(name).to eq "Total_Items_All_Institutions_2023-04-01.csv"

          r = CSV.parse(report)

          expect(r[0]).to eq ["Institution", "Count"]
          expect(r[1]).to eq ["U of A", "2"]
          expect(r[2]).to eq ["U of B", "1"]
        end
      end
    end

    describe "#modified_item_reports" do
      it "creates correct reports" do
        travel_to("2023-04-01") do
          report_time = RecurringUsageReport::ReportTime.from_interval("last_week")
          reports = described_class.new.modified_item_reports(report_time, product.group_key, press.subdomain)

          expect(reports["U_of_A_2023-04-01.csv"]).to be_present
          expect(reports["U_of_B_2023-04-01.csv"]).to be_present

          a = CSV.parse(reports["U_of_A_2023-04-01.csv"])
          b = CSV.parse(reports["U_of_B_2023-04-01.csv"])

          expect(a[0]).to eq ["Authors", "Publication_Date", "DOI", "Parent_Title", "Parent_DOI", "Component_Title", "Data_Type", "YOP", "Access_Type", "Reporting_Period_Total"]
          expect(a[1]).to eq ["C FileSet Author", "2001", "doi.org/c_file_set", "Green Title", "doi.org/green_book", "Chapter Green", "Book", "2001", "OA_Gold", "1"]
          expect(a[2]).to eq ["Red Author", "2000", "doi.org/a_file_set", "Red", "doi.org/red_book", "", "Book", "2000", "Controlled", "1"]

          expect(b[0]).to eq ["Authors", "Publication_Date", "DOI", "Parent_Title", "Parent_DOI", "Component_Title", "Data_Type", "YOP", "Access_Type", "Reporting_Period_Total"]
          expect(b[1]).to eq ["Blue Author", "1999", "doi.org/b_file_set", "Blue", "doi.org/blue_book", "Chapter R", "Book", "1999", "Controlled", "1"]
        end
      end
    end
  end

  describe "#subscribers_for_products" do
    let(:institution1) { create(:institution, identifier: 1) }
    let(:institution2) { create(:institution, identifier: 2) }
    let!(:institution3) { create(:institution, identifier: 3) }
    let(:product) { create(:product, identifier: "something", group_key: "bar") }

    before do
      create(:full_license, licensee: institution1, product: product)
      create(:full_license, licensee: institution2, product: product)
    end

    it "returns subscribed institutions" do
      expect(described_class.new.subscribers_for_products("bar")).to eq [institution1, institution2]
    end
  end
end

RSpec.describe RecurringUsageReport::ReportTime do
  describe "#self.from_interval" do
    context "with an incorrect time_interval" do
      it "raises an error" do
        expect { described_class.from_interval("something") }.to raise_error("Only time_intervals of 'last_week' accepted, you gave: something")
      end
    end

    context "on 2023-04-01 (saturday)" do
      it "returns the correct start and end dates" do
        travel_to("2023-04-01") do
          expect(described_class.from_interval("last_week").start_date).to eq "2023-03-25"
          expect(described_class.from_interval("last_week").end_date).to eq "2023-03-31"
        end
      end
    end
  end

  describe "self.from_given_dates" do
    context "with a bad start date" do
      it "raises and error" do
        expect { described_class.from_given_dates("2010-01", "2010-12-31") }.to raise_error("given_start_date must be in format YYYY-MM-DD")
      end
    end

    context "with a bad end date" do
      it "raises an error" do
        expect { described_class.from_given_dates("2023-01-01", "31") }.to raise_error("given_end_date must be in format YYYY-MM-DD")
      end
    end

    context "with given dates" do
      it "returns those dates" do
        expect(described_class.from_given_dates("2020-01-01", "2020-10-31").start_date).to eq "2020-01-01"
        expect(described_class.from_given_dates("2020-01-01", "2020-10-31").end_date).to eq "2020-10-31"
      end
    end
  end
end
