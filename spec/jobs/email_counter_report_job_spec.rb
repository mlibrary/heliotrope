# frozen_string_literal: true

require 'rails_helper'
require 'zlib'

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

    let(:tmp) { Tempfile.new }
    let(:gzipped_csv_report) do
      Zlib::GzipWriter.open(tmp) do |fo|
        fo.write CounterReporterService.csv(report)
      end
      tmp
    end

    let(:email_subject) { "Fulcrum COUNTER 5 report #{report_type.upcase} for \"#{institution.name}\" of the Press \"#{press.name}\" from #{args[:start_date]} to #{args[:end_date]}" }
    let(:mailer) { double("mailer", deliver_now: true) }

    before do
      allow(CounterReporterService).to receive(:pr_p1).with(args).and_return(report)
      allow(Tempfile).to receive(:new).and_return(tmp)
      allow(CounterReportMailer).to receive(:send_report).with({ email: press_admin.email,
                                                                 email_subject: email_subject,
                                                                 csv_file: gzipped_csv_report,
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
                                                                        csv_file: gzipped_csv_report,
                                                                        press: press.name,
                                                                        institution: institution.name,
                                                                        report_type: report_type.upcase,
                                                                        start_date: args[:start_date],
                                                                        end_date: args[:end_date] })
    end
  end
end
