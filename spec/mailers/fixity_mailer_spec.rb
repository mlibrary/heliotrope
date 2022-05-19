
# frozen_string_literal: true

require "rails_helper"

RSpec.describe FixityMailer, type: :mailer do
  describe '#send_failures' do
    let(:today) { Time.zone.now.strftime "%Y-%m-%d" }
    let(:failures) do
      [
        {
          passed: 'false',
          file_set_id: 'FILE_SET_NOID',
          file_id: 'FILE_SET_NOID/files/FILE_ID',
        }
      ]
    end
    let(:mail) { described_class.send_failures(failures).deliver }

    before do
      allow(Settings).to receive(:host).and_return("www.fulcrum.org")
    end

    it "has the correct fields" do
      expect(mail.from).to eq ["fulcrum-dev@umich.edu"]
      expect(mail.to).to eq ["fulcrum-dev@umich.edu"]
      expect(mail.subject).to eq "Fulcrum Fixity Failure(s)"
      expect(mail.body.encoded).to match("FILE_SET_NOID")
      expect(mail.body.encoded).to match("FILE_SET_NOID/files/FILE_ID")
      expect(mail.body.encoded).to match(today)
    end
  end
end
