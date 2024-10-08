# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarcIngestMailer, type: :mailer do
  describe "#send_mail" do
    let(:today) { Time.zone.now.strftime "%Y-%m-%d" }
    let(:report) do
      [
        "SUCCESS this_group_key this_noid this_marc_file.mrc moved to /MARC_from_Cataloging/product_dir",
        "ERROR test_marc.xml has no 024 $a field"
      ]
    end

    let(:mail) { described_class.send_mail(report) }

    it "has the correct values in the email" do
      expect(mail.from).to eq ["fulcrum-dev@umich.edu"]
      expect(mail.to).to eq ["sethajoh@umich.edu"]
      expect(mail.subject).to eq "MARC Ingest Report"
      expect(mail.body.encoded).to match(today)
      expect(mail.body.encoded).to match("SUCCESS this_group_key this_noid this_marc_file.mrc moved to /MARC_from_Cataloging/product_dir")
      expect(mail.body.encoded).to match("ERROR test_marc.xml has no 024")
    end
  end
end
