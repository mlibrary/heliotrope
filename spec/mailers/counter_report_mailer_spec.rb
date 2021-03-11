
# frozen_string_literal: true

require "rails_helper"
require "zlib"

RSpec.describe CounterReportMailer, type: :mailer do
  describe '#send_report' do
    let(:press) { create(:press, subdomain: "blue", name: "The Blue Press") }
    let(:press_admin) { create(:press_admin, press: press) }
    let(:email_subject) { "TR_B1 #{institution.name} #{press.name}" }
    let(:report_type) { "tr_b1" }
    let(:institution) { create(:institution) }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-02-28" }
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
    let(:zip_file) { EmailCounterReportJob.new.build_zip(report_type, email_subject, report) }

    let(:mail) { described_class.send_report({ email: press_admin.email,
                                               zip_file: zip_file,
                                               email_subject: email_subject,
                                               press: press.name,
                                               institution: institution.name,
                                               report_type: report_type,
                                               start_date: start_date,
                                               end_date: end_date
                                             }).deliver }

    it "has the correct fields and attachment" do
      expect(mail.from).to eq ["fulcrum-info@umich.edu"]
      expect(mail.to).to eq [press_admin.email]
      expect(mail.subject).to eq(email_subject)
      expect(mail.body.encoded).to match("Institution: #{institution.name}")
      expect(mail.body.encoded).to match("Collection: #{press.name}")
      expect(mail.body.encoded).to match("Report: #{report_type}")
      expect(mail.body.encoded).to match("Date range: #{start_date} through #{end_date}")
      expect(mail.attachments[0].main_type).to eq "application"
      expect(mail.attachments[0].sub_type).to eq "zip"
      expect(mail.attachments[0].filename).to eq "TR_B1_#{institution.name}_The_Blue_Press.zip"
    end
  end
end
