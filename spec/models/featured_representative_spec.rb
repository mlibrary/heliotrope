# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedRepresentative, type: :model do
  describe '#kinds' do
    it { expect(described_class.kinds).to eq %w[aboutware audiobook database epub mobi pdf_ebook peer_review related reviews webgl] }
  end


  describe "file_set" do
    let!(:fr1) { create(:featured_representative, work_id: 1, file_set_id: 1, kind: 'epub') }

    it "is unique" do
      expect { described_class.create!(work_id: 2, file_set_id: 1, kind: 'epub') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: File set has already been taken")
    end
  end

  describe "kind" do
    it "is valid" do
      expect { described_class.create!(work_id: 1, file_set_id: 1, kind: 'kind') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Kind is not included in the list")
    end
  end

  describe "work and kind" do
    let!(:fr1) { create(:featured_representative, work_id: 1, file_set_id: 1, kind: 'epub') }

    it "is unique" do
      expect { described_class.create!(work_id: 1, file_set_id: 2, kind: 'epub') }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Kind Work can only have one of each kind")
    end
  end
end
