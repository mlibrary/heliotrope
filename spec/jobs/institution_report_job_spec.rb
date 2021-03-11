# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstitutionReportJob, type: :job do
  describe "perform" do
    let(:press) { create(:press, subdomain: "blue", name: "The Blue Press") }
    let(:press_admin) { create(:user, press: press) }
    let(:start_date) { "2018-01-01" }
    let(:end_date) { "2018-02-28" }
    let(:report_type) { "request" }
    let(:report_heading) { "Total_Item_Requests for all Institutions #{press.name} #{start_date} to #{end_date}" }
    let(:report_name) { "Total_Item_Requests" }
    let(:tmpfile) { Tempfile.new }
    let(:mailer) { double("mailer", deliver_now: true) }
    let(:results) do
      {
        "One Institution": { "Jan-2018": 1, "Feb-2018": 0 },
        "Two Institution": { "Jan-2018": 1, "Feb-2018": 1 }
      }
    end

    let(:csv) do
      <<-CSV
#{report_heading},"",""
"",Jan-2018,Feb-2018
One Institution,1,0
Two Institution,1,1
      CSV
    end

    before do
      allow(InstitutionReportService).to receive(:run).and_return(results)
      allow(InstitutionReportService).to receive(:make_csv).with(subject: report_heading, results: results).and_return(csv)
      allow(Tempfile).to receive(:new).and_return(tmpfile)
      allow(ReportMailer).to receive(:send_report).with({ email: press_admin.email,
                                                          report_heading: report_heading,
                                                          csv_file: tmpfile,
                                                          report_name: report_name,
                                                          press: press.name,
                                                          start_date: start_date.to_s,
                                                          end_date: end_date.to_s
                                                        }).and_return(mailer)
    end

    it "calls the ReportMailer with the correct params" do
      described_class.perform_now(args: { email: press_admin.email, press: press.id, start_date: start_date, end_date: end_date, report_type: report_type })
      expect(ReportMailer).to have_received(:send_report).with({ email: press_admin.email,
                                                                 report_heading: report_heading,
                                                                 csv_file: tmpfile,
                                                                 report_name: report_name,
                                                                 press: press.name,
                                                                 start_date: start_date.to_s,
                                                                 end_date: end_date.to_s
                                                              })
    end
  end
end
