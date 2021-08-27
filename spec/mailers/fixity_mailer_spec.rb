
# frozen_string_literal: true

require "rails_helper"

RSpec.describe FixityMailer, type: :mailer do
  describe '#send_failures' do
    let(:today) { Time.zone.now.to_s }
    let(:failures) do
      [
        {
          passed: 'false',
          file_set_id: 'FILE_SET_NOID',
          file_id: 'FILE_SET_NOID/files/FILE_ID',
          tries: '3'
        }
      ]
    end
    let(:mail) { described_class.send_failures(failures).deliver }

    it "has the correct fields" do
      expect(mail.from).to eq ["fulcrum-dev@umich.edu"]
      expect(mail.to).to eq ["fulcrum-dev@umich.edu"]
      expect(mail.subject).to eq "Fulcrum Fixity Failure(s)"
      expect(mail.body.encoded).to match("FILE_SET_NOID")
      expect(mail.body.encoded).to match("FILE_SET_NOID/files/FILE_ID")
      expect(mail.body.encoded).to match("3")
      expect(mail.body.encoded).to match(today)
    end
  end
end
