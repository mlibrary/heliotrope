# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpackService do
  let(:noid) { '123456789' }
  let(:kind) { 'epub' }

  describe "#root_path_from_noid" do
    it { expect(described_class.root_path_from_noid(noid, kind)).to match(/\/12\/34\/56\/78\/9-epub$/) }
  end

  describe "#noid_from_root_path" do
    let(:root_path) { described_class.root_path_from_noid(noid, kind) }

    it { expect(described_class.noid_from_root_path(root_path, kind)).to eq noid }
  end

  describe "#remove_path_from_noid" do
    before do
      allow(DateTime).to receive(:now).and_return(9999)
    end

    it { expect(described_class.remove_path_from_noid(noid, kind)).to match(/\/12\/34\/56\/78\/TO-BE-REMOVED-9999-epub/) }
  end
end
