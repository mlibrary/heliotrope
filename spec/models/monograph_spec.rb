# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  subject { monograph }

  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  it('includes HeliotropeUniverialMetadata') { is_expected.to be_a HeliotropeUniversalMetadata }

  it "has date_published" do
    monograph.date_published = [date]
    expect(monograph.date_published).to eq [date]
  end

  it 'can set the press with a string' do
    monograph.press = umich.subdomain
    expect(monograph.press).to eq umich.subdomain
  end

  it 'must have a press and title' do
    mono = described_class.new
    # note `mono.errors.messages` not populated until `mono.valid?` is called
    expect(mono.valid?).to eq false
    expect(mono.errors.messages[:press]).to eq ['You must select a press.']
    expect(mono.errors.messages[:title]).to eq ['Your work must have a title.']
    monograph.press = umich.subdomain
    monograph.title = ['blah']
    expect(monograph.valid?).to eq true
  end

  context "edition information" do
    it "validates previous_edition and next_edition as a URLs if they are present" do
      monograph.press = umich.subdomain
      monograph.title = ['blah']
      expect(monograph.valid?).to eq true
      monograph.previous_edition = 'blah'
      # note `monograph.errors.messages` not populated until `monograph.valid?` is called
      expect(monograph.valid?).to eq false
      expect(monograph.errors.messages[:previous_edition]).to eq ['must be a url.']
      monograph.previous_edition = 'https://fulcrum.org/concerns/monographs/000000000'
      expect(monograph.valid?).to eq true
      monograph.next_edition = 'blah'
      # note `monograph.errors.messages` not populated until `monograph.valid?` is called
      expect(monograph.valid?).to eq false
      expect(monograph.errors.messages[:next_edition]).to eq ['must be a url.']
      monograph.next_edition = 'https://fulcrum.org/concerns/monographs/111111111'
      expect(monograph.valid?).to eq true
    end
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
