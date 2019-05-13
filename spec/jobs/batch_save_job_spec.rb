# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchSaveJob, type: :job do
  context "with valid data" do
    let(:monograph) { create(:monograph) }
    let(:file_set) { create(:file_set) }
    let(:data) do
      {
        monograph.id => { doi: "mdoi" },
        file_set.id => { doi: "fdoi" }
      }
    end

    it "saves the fields" do
      described_class.perform_now(data)
      expect(monograph.reload.doi).to eq 'mdoi'
      expect(file_set.reload.doi).to eq 'fdoi'
    end
  end

  context "with a bad noid" do
    let(:data) do
      { "99999999" => { doi: "xfkjd" } }
    end

    it "does nothing" do
      expect { described_class.perform_now(data) }.not_to raise_error
    end
  end

  context "with an invalid field" do
    let(:file_set) { create(:file_set) }
    let(:data) { { file_set.id => { not_a_real_thing: "oops" } } }

    it "raises NoMethodError" do
      expect { described_class.perform_now(data) }.to raise_error(NoMethodError)
    end
  end
end
