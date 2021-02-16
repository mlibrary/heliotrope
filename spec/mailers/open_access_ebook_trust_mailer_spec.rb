
# frozen_string_literal: true

require "rails_helper"
require "zlib"

RSpec.describe OpenAccessEbookTrustMailer, type: :mailer do
  describe '#send_report' do
    let(:reports) do
      {
        "first report" => "first report cvs data",
        "second report" => "second report csv data"
      }
    end
    let(:tmp_zip) { OpenAccessEbookTrustJob.new.zipup(reports) }

    it "has the correct fields and attachment" do
      travel_to(Time.parse("2020-02-01")) do
        described_class.send_report(tmp_zip).deliver
        email = ActionMailer::Base.deliveries.last
        expect(email.from).to eq ["fulcrum-info@umich.edu"]
        expect(email.subject).to eq "Monthly Fulcrum reports for OAeBU Data Trust"
        expect(email.to).to eq ["test@fulcrum"]
        expect(email.cc).to eq ["cc1@fulcrum", "cc2@fulcrum"]
        expect(email.attachments[0].main_type).to eq "application"
        expect(email.attachments[0].sub_type).to eq "zip"
        expect(email.attachments[0].filename).to eq "Monthly_Fulcrum_Reports_January_2020.zip"
      end
    end
  end
end
