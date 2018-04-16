# frozen_string_literal: true

require 'rails_helper'

describe Monograph do
  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

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
end
