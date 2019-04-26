# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrossrefSubmissionLog, type: :model do
  describe "validations" do
    it "only takes valid statuses" do
      expect(described_class.create(status: "bewildered")).not_to be_valid
    end
  end
end
