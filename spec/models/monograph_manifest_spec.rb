# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographManifest, type: :model do
  subject(:monograph_manifest) { described_class.new(monograph.id) }

  let(:monograph) { double("monograph", id: noid) }
  let(:noid) { "123456789" }
  let(:implicit_manifest) { double("implicit_manifest") }
  let(:explicit_manifest) { double("explicit_manifest") }

  before do
    allow(Manifest).to receive(:from_monograph).with(noid).and_return(implicit_manifest)
    allow(Manifest).to receive(:from_monograph_manifest).with(noid).and_return(explicit_manifest)
  end

  it { expect(monograph_manifest.id).to eq noid }
  it { expect(monograph_manifest.implicit).to be implicit_manifest }
  it { expect(monograph_manifest.explicit).to be explicit_manifest }
  it { expect(monograph_manifest.persisted?).to be true }
end
