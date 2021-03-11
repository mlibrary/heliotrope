# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe EmailCounterReportJob, type: :job do
  describe "perform" do
    let(:press) { create(:press, subdomain: "blue", name: "The Blue Press") }
    let(:institution) { create(:institution) }
    let(:press_admin) { create(:user, press: press) }
    let(:email) { press_admin.email }
    let(:report_type) { "pr_p1" }
    let(:args) do
      {
        press: press.id,
        institution: institution.identifier,
        start_date: "2020-01-01",
        end_date: "2020-05-01"
      }.with_indifferent_access
    end

    let(:email_subject) { "Fulcrum #{report_type.upcase} \"#{institution.name}\" \"#{press.name}\" #{args[:start_date]} to #{args[:end_date]}" }
    let(:mailer) { double("mailer", deliver_now: true) }
    let(:report) do
      {
        header: { "Report header field": "value" },
        items: [
          {
            "A COUNTER field": "a value",
            "Another field": "another value"
          },
          {
            "A COUNTER field": "b value",
            "Another field:": "b another value"
          }
        ]
      }
    end

    # We test building the zip in #build_zip below, so this can be mocked.
    let(:mock_zip) { double('mock_zip') }

    before do
      allow_any_instance_of(described_class).to receive(:build_zip).and_return(mock_zip)
      allow(CounterReporterService).to receive(:pr_p1).with(args).and_return(report)
      allow(CounterReportMailer).to receive(:send_report).with({ email: press_admin.email,
                                                                 email_subject: email_subject,
                                                                 zip_file: mock_zip,
                                                                 press: press.name,
                                                                 institution: institution.name,
                                                                 report_type: report_type.upcase,
                                                                 start_date: args[:start_date],
                                                                 end_date: args[:end_date] }).and_return(mailer)
    end

    it "calls the CounterReportMailer with the correct params" do
      described_class.perform_now(email: press_admin.email, report_type: report_type, args: args)
      expect(CounterReportMailer).to have_received(:send_report).with({ email: press_admin.email,
                                                                        email_subject: email_subject,
                                                                        zip_file: mock_zip,
                                                                        press: press.name,
                                                                        institution: institution.name,
                                                                        report_type: report_type.upcase,
                                                                        start_date: args[:start_date],
                                                                        end_date: args[:end_date] })
    end
  end

  describe "#build_zip" do
    let(:report_type) { "pr_p1" }
    let(:email_subject) { "PR_P1 Institution Press 2020-01-01 to 2020-10-01" }
    let(:report) do
      {
        header: { "Report header field": "value" },
        items: [
          {
            "A COUNTER field": "a value",
            "Another field": "another value"
          },
          {
            "A COUNTER field": "b value",
            "Another field:": "b another value"
          }
        ]
      }
    end

    it "returns a zipped archive containing the report" do
      Zip::File.open(described_class.new.build_zip(report_type, email_subject, report)) do |zip_file|
        zip_file.each do |entry|
          expect(entry.name).to eq "PR_P1_Institution_Press_2020-01-01_to_2020-10-01.csv"
          expect(entry.get_input_stream.read).to eq CounterReporterService.csv(report)
        end
      end
    end
  end
end
