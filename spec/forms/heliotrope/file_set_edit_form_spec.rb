# frozen_string_literal: true

require 'rails_helper'

describe Heliotrope::FileSetEditForm do
  describe "terms" do
    let(:admin) { create(:platform_admin) }
    let(:ability) { Ability.new(admin) }
    let(:file_set) { FileSet.new }
    let(:form) { described_class.new(file_set, ability, Hyrax::FileSetController) }

    it "field to put arbitrary json exists" do
      expect(described_class.terms.include?(:extra_type_properties)).to be true
    end

    it "Score specific field(s) exist" do
      # These are in the Form so we don't trigger "unpermitted parameters", but they
      # are not in the FileSet model. Instead, the FileSetController will put their
      # contents in the json in extra_type_properties then delete the field
      expect(described_class.terms.include?(:score_version)).to be true
    end
  end
end
