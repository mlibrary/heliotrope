# frozen_string_literal: true

require 'rails_helper'

# These are just hashes, tests are kind of pointless but we'll do a couple of them
# to illustrate the need for the mapping in the first place.
RSpec.describe Marc::DirectoryMapper do
  describe "#group_key_cataloging" do
    context "with a valid group_key" do
      # group_key "umpebc" maps to "UMPEBC"
      let(:group_key) { 'umpebc' }
      it "returns a path to a cataloging directory for that group_key" do
        expect(described_class.group_key_cataloging[group_key]).to eq "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC"
      end
    end

    context "with an invalid group_key" do
      let(:group_key) { 'not_valid' }
      it "returns nil" do
        expect(described_class.group_key_cataloging[group_key]).to be nil
      end
    end
  end

  describe "#group_key_kbart" do
    context "with a valid group_key" do
      # group_key "amherst" maps to "Amherst_College_Press"
      let(:group_key) { 'amherst' }
      it "returns a path to a kbart directory for that group_key" do
        expect(described_class.group_key_kbart[group_key]).to eq "/home/fulcrum_ftp/ftp.fulcrum.org/Amherst_College_Press/KBART"
      end
    end

    context "with an invalid group_key" do
      let(:group_key) { 'not_valid' }
      it "returns nil" do
        expect(described_class.group_key_cataloging[group_key]).to be nil
      end
    end
  end
end
