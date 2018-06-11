# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReport, type: :model do
  describe "validations" do
    it "only takes valid access_types" do
      expect(described_class.create(access_type: "No")).to_not be_valid
    end
    it "only takes valid turnaway" do
      expect(described_class.create(turnaway: "No")).to_not be_valid
    end
    it "ony takes valid section_type" do
      expect(described_class.create(section_type: "Magazine")).to_not be_valid
    end
  end
end
