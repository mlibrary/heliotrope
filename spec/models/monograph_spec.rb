# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  subject { monograph }

  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  it 'includes HeliotropeUniverialMetadata' do
    is_expected.to be_a HeliotropeUniversalMetadata
  end

  it "has date_published" do
    monograph.date_published = [date]
    expect(monograph.date_published).to eq [date]
  end

  it 'can set the press with a string' do
    monograph.press = umich.subdomain
    expect(monograph.press).to eq umich.subdomain
  end

  it 'must have a press' do
    mono = described_class.new
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:press]).to eq ['You must select a press.']
  end

  context 'handles' do
    let(:monograph) { build(:monograph, id: noid) }
    let(:noid) { 'validnoid' }

    before do
      ActiveFedora::Cleaner.clean!
      allow(HandleCreateJob).to receive(:perform_later).with(noid)
      allow(HandleDeleteJob).to receive(:perform_later).with(noid)
    end

    it 'creates a handle after create and deletes the handle after destroy' do
      monograph.save
      expect(HandleCreateJob).to have_received(:perform_later).with(noid)
      monograph.destroy
      expect(HandleDeleteJob).to have_received(:perform_later).with(noid)
    end
  end
end
