# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedRepresentative, type: :model do
  describe '#kinds' do
    it { expect(described_class.kinds).to eq %w[epub webgl database aboutware] }
  end

  describe "the combination of mongraph_id, file_set_id and kind" do
    let!(:fr1) { create(:featured_representative, monograph_id: 1, file_set_id: 1, kind: 'epub') }
    it "is unique" do
      expect(described_class.create(monograph_id: 1, file_set_id: 1, kind: 'epub')).to_not be_valid
    end
  end
end
