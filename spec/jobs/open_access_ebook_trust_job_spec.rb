# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenAccessEbookTrustJob, type: :job do
  describe "perform" do
    let(:mailer) { double("mailer", deliver_now: true) }
    let(:mock_zip) { double('mock_zip') }
    let!(:press) { create(:press, subdomain: "michigan") }

    before do
      allow(OpenAccessEbookTrustMailer).to receive(:send_report).with(mock_zip).and_return(mailer)
      # This is SUPER mocky, it's bad to mock the system under test, obvs.
      # Because the methods in this job are being tested individually I'm
      # justifiying this. But I agree, it's not great.
      # An alternative I experimented with was setting up the system state with like 100 variables,
      # monographs, file_sets, featured_reps, counter report counts, greensub institutions/products/components
      # and then zipping all the results. I don't know. I didn't like that either.
      allow_any_instance_of(described_class).to receive(:zipup).and_return(mock_zip)
    end

    it "calls the mailer" do
      travel_to(Time.parse("2020-05-01")) do
        described_class.perform_now
        expect(OpenAccessEbookTrustMailer).to have_received(:send_report).with(mock_zip)
      end
    end

    context "with given start and end dates" do
      # This too is a big mess. We just want to make sure the given dates are being passed
      # around instead of the defaults
      let!(:target) { create(:full_license, licensee: institution, product: product) }
      let(:institution) { create(:institution) }
      let(:product) { create(:product, identifier: "ebc_YYYY") }
      let(:report_time) { OpenAccessEbookTrust::ReportTime.new("2022-02-14", "2022-06-11") }
      let(:counter_items) { double("counter items") }

      before do
        allow(CounterReporter::ReportParams).to receive(:new).with(
          'ir',
          {
            institution: institution.identifier,
            start_date: report_time.start_date,
            end_date: report_time.end_date,
            press: press.id,
            metric_type: 'Total_Item_Requests',
            data_type: ["Book", "Multimedia", "Book_Segment"],
            access_type: ['Controlled', 'OA_Gold'],
            access_method: 'Regular',
            attributes_to_show: ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"],
            include_parent_details: "true",
            exclude_monthly_details: "false",
            include_monthly_details: "true"
          }
        )
        allow(CounterReporter::ItemReport).to receive(:new).and_return(counter_items)
        allow(counter_items).to receive(:report).and_return([])
      end

      it "calls the mailer, methods get report_time object" do
        described_class.perform_now("michigan", "2022-02-14", "2022-06-11")
        expect(CounterReporter::ReportParams).to have_received(:new).with(
          'ir',
          {
            institution: institution.identifier,
            start_date: report_time.start_date,
            end_date: report_time.end_date,
            press: press.id,
            metric_type: 'Total_Item_Requests',
            data_type: ["Book", "Multimedia", "Book_Segment"],
            access_type: ['Controlled', 'OA_Gold'],
            access_method: 'Regular',
            attributes_to_show: ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"],
            include_parent_details: "true",
            exclude_monthly_details: "false",
            include_monthly_details: "true"
          }
        )
        expect(OpenAccessEbookTrustMailer).to have_received(:send_report).with(mock_zip)
      end
    end
  end

  describe "#institutions" do
    let(:inst1) { create(:institution, identifier: 1, name: "UofA") }
    let(:inst2) { create(:institution, identifier: 2, name: "UofB") }
    let(:indv1) { create(:individual, identifier: 3, name: "Frank") }
    let(:prod1) { create(:product, identifier: "ebc_123") }
    let(:prod2) { create(:product, identifier: "ebc_rrr") }

    before do
      inst1.create_product_license(prod1)
      inst2.create_product_license(prod2)
      inst1.create_product_license(prod1)
    end

    it "returns institutions that are subscribed to ebc_* products" do
      expect(described_class.new.institutions).to eq [inst1, inst2]
    end
  end

  describe "#usage_report" do
    let(:royalty) { double("royalty") }
    let(:result) { double("result") }
    let(:output) { "report csv data" }
    let(:name) { "Royalty Usage Report for University of Michigan Press in the Humanities EBook Collection from 2019-07-01 to 2019-12-31" }

    before do
      allow(Royalty::UsageReport).to receive(:new).with("heb", "2019-07-01", "2019-12-31").and_return(royalty)
      allow(royalty).to receive(:report_for_copyholder).with("University of Michigan Press").and_return(result)
      allow(CounterReporterService).to receive(:csv).with(result).and_return(output)
      allow(result).to receive(:[]).and_return(["stuff"])
    end

    it "returns a royalty usage report" do
      travel_to(Time.parse("2020-01-01")) do
        expect(described_class.new.usage_report(OpenAccessEbookTrust::ReportTime.new, { "name" => "data" })).to eq (
          {
            "name" => "data",
            "#{name}" => "#{output}"
          }
        )
      end
    end
  end

  describe "#item_master_reports" do
    let(:press) { create(:press, subdomain: "michigan", name: "UMich") }
    let(:inst1) { create(:institution, identifier: 1, name: "UofA") }
    let(:inst2) { create(:institution, identifier: 2, name: "UofB") }
    let(:prod1) { create(:product, identifier: "ebc_123") }
    let(:prod2) { create(:product, identifier: "ebc_rrr") }
    let(:start_date) { "2020-01-01" }
    let(:end_date) { "2020-01-31" }
    let(:inst1params) { double("inst1params") }
    let(:inst2params) { double("inst2params") }
    let(:report1) { double("report1", report: "data for #{inst1.name}") }
    let(:report2) { double("report2", report: "data for #{inst2.name}") }
    let(:report1_csv) { "csv for #{inst1.name}" }
    let(:report2_csv) { "csv for #{inst2.name}" }
    let(:report1_name) { "Item Master Report Total_Item_Requests of #{press.name} for #{inst1.name} from #{start_date} to #{end_date}" }
    let(:report2_name) { "Item Master Report Total_Item_Requests of #{press.name} for #{inst2.name} from #{start_date} to #{end_date}" }

    before do
      inst1.create_product_license(prod1)
      inst2.create_product_license(prod2)
      allow(CounterReporter::ReportParams).to receive(:new).with('ir', {
        institution: inst1.identifier,
        start_date: start_date,
        end_date: end_date,
        press: press.id,
        metric_type: 'Total_Item_Requests',
        data_type: ["Book", "Multimedia", "Book_Segment"],
        access_type: ['Controlled', 'OA_Gold'],
        access_method: 'Regular',
        attributes_to_show: ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"],
        include_parent_details: "true",
        exclude_monthly_details: "false",
        include_monthly_details: "true"
      }).and_return(inst1params)
      allow(CounterReporter::ReportParams).to receive(:new).with('ir', {
        institution: inst2.identifier,
        start_date: start_date,
        end_date: end_date,
        press: press.id,
        metric_type: 'Total_Item_Requests',
        data_type: ["Book", "Multimedia", "Book_Segment"],
        access_type: ['Controlled', 'OA_Gold'],
        access_method: 'Regular',
        attributes_to_show: ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"],
        include_parent_details: "true",
        exclude_monthly_details: "false",
        include_monthly_details: "true"
      }).and_return(inst2params)
      allow(CounterReporter::ItemReport).to receive(:new).with(inst1params).and_return(report1)
      allow(CounterReporter::ItemReport).to receive(:new).with(inst2params).and_return(report2)
      allow(CounterReporterService).to receive(:csv).with(report1.report).and_return(report1_csv)
      allow(CounterReporterService).to receive(:csv).with(report2.report).and_return(report2_csv)
    end

    it "return reports for each institution" do
      travel_to(Time.parse("2020-02-01")) do
        expect(described_class.new.item_master_reports(OpenAccessEbookTrust::ReportTime.new, press, {})).to eq (
          {
            report1_name => report1_csv,
            report2_name => report2_csv
          }
        )
      end
    end
  end

  describe "#instituion_reports" do
    let(:press) { create(:press, subdomain: "michigan", name: "UMich") }
    let(:institutions) { [] }
    let(:start_date) { "2020-01-01" }
    let(:end_date) { "2020-01-31" }
    let(:requests) { "request data" }
    let(:request_csv) { "request data in csv" }
    let(:request_name) { "Total_Item_Requests for all Institutions for #{press.name} from #{start_date} to #{end_date}" }
    let(:request_args) do
      {
        start_date: start_date,
        end_date: end_date,
        press: press.id,
        institutions: institutions,
        report_type: "request"
      }
    end
    let(:investigations) { "investigation data" }
    let(:investigation_csv) { "investigation data in csv" }
    let(:investigation_name) { "Total_Item_Investigations for all Institutions for #{press.name} from #{start_date} to #{end_date}" }
    let(:investigation_args) do
      {
        start_date: start_date,
        end_date: end_date,
        press: press.id,
        institutions: institutions,
        report_type: "investigation"
      }
    end

    before do
      allow(InstitutionReportService).to receive(:run).with(args: request_args).and_return(requests)
      allow(InstitutionReportService).to receive(:make_csv).with(subject: request_name, results: requests).and_return(request_csv)
      allow(InstitutionReportService).to receive(:run).with(args: investigation_args).and_return(investigations)
      allow(InstitutionReportService).to receive(:make_csv).with(subject: investigation_name, results: investigations).and_return(investigation_csv)
    end

    it "returns reports" do
      travel_to("2020-02-01") do
        expect(described_class.new.institution_reports(OpenAccessEbookTrust::ReportTime.new, press, {})).to eq (
          {
            request_name => request_csv,
            investigation_name => investigation_csv
          }
        )
      end
    end
  end

  describe "#zipup" do
    after { File.unlink(File.join(Settings.scratch_space_path, "fulcrum_ebc_reports_zip")) }

    let(:reports) do
      {
        "A Report" => "A Report csv data",
        "B Report" => "B Report csv data",
        "C Report" => "C Report csv data"
      }
    end

    it "returns a zipped archive containing reports" do
      Zip::File.open(described_class.new.zipup(reports)) do |zip|
        expect(zip.entries[0].name).to eq "A_Report.csv"
        expect(zip.entries[0].get_input_stream.read).to eq "A Report csv data"
        expect(zip.entries[1].name).to eq "B_Report.csv"
        expect(zip.entries[1].get_input_stream.read).to eq "B Report csv data"
        expect(zip.entries[2].name).to eq "C_Report.csv"
        expect(zip.entries[2].get_input_stream.read).to eq "C Report csv data"
      end
    end
  end
end

RSpec.describe OpenAccessEbookTrust::ReportTime do
  context "with the default start and end date" do
    describe "#start_date" do
      it "returns the first of the previous month" do
        travel_to(Time.parse("2020-02-01")) do
          expect(described_class.new.start_date).to eq "2020-01-01"
        end

        travel_to(Time.parse("2020-01-01")) do
          expect(described_class.new.start_date).to eq "2019-12-01"
        end
      end
    end

    describe "#end_date" do
      it "returns the last day of the previous month" do
        travel_to(Time.parse("2020-02-01")) do
          expect(described_class.new.end_date).to eq "2020-01-31"
        end

        travel_to(Time.parse("2020-01-01")) do
          expect(described_class.new.end_date).to eq "2019-12-31"
        end
      end
    end

    describe "#usage_report_start_date" do
      it "returns the first day of the month 6 months ago" do
        travel_to(Time.parse("2020-01-01")) do
          expect(described_class.new.usage_report_start_date).to eq "2019-07-01"
        end

        travel_to(Time.parse("2020-07-01")) do
          expect(described_class.new.usage_report_start_date).to eq "2020-01-01"
        end
      end
    end

    describe "#january_or_july?" do
      context "if january" do
        it "returns true" do
          travel_to(Time.parse("2020-01-01")) do
            expect(described_class.new.january_or_july?).to be true
          end
        end
      end
      context "if july" do
        it "returns true" do
          travel_to(Time.parse("2020-07-01")) do
            expect(described_class.new.january_or_july?).to be true
          end
        end
      end
      context "if october" do
        it "returns false" do
          travel_to(Time.parse("2020-10-01")) do
            expect(described_class.new.january_or_july?).to be false
          end
        end
      end
    end
  end

  context "with a given start and end date" do
    context "with the wrong date format" do
      it "raises" do
        expect { described_class.new("02/02/2022") }.to raise_error(RuntimeError, "given_start_date must be in format YYYY-MM-DD")
        expect { described_class.new("2022-02-02", "Monday") }.to raise_error(RuntimeError, "given_end_date must be in format YYYY-MM-DD")
      end
    end

    describe "#start_date" do
      it "returns the given start date" do
        expect(described_class.new("2022-02-02", "2022-07-04").start_date).to eq "2022-02-02"
      end
    end

    describe "#end_date" do
      it "returns the given end date" do
        expect(described_class.new("2022-02-02", "2022-07-04").end_date).to eq "2022-07-04"
      end
    end

    describe "#usage_report_start_date" do
      it "returns the first day of the month 6 months before the given start date" do
        expect(described_class.new("2022-02-02", "2022-07-04").usage_report_start_date).to eq "2021-08-01"
      end
    end

    describe "#january_or_july?" do
      it { expect(described_class.new("2022-02-02", "2022-07-04").january_or_july?).to be false }
      it { expect(described_class.new("2022-07-01", "2022-09-14").january_or_july?).to be true }
      it { expect(described_class.new("2022-01-27", "2022-09-14").january_or_july?).to be true }
    end
  end
end
