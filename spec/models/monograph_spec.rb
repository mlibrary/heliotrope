# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  let(:imprint) { create(:sub_brand, title: 'UM Press Literary Classics') }
  let(:series) { create(:sub_brand, title: "W. Shakespeare Collector's Series") }

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

  it 'can have sub-brands' do
    expect(monograph.sub_brand).to eq []
    monograph.sub_brand << imprint.id
    monograph.sub_brand << series.id
    expect(monograph.sub_brand).to contain_exactly(imprint.id, series.id)
  end
end
