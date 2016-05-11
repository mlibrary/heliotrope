require 'rails_helper'

describe Monograph do
  let(:monograph) { described_class.new }
  let(:date) { DateTime.now }
  let(:umich) { build(:press, subdomain: 'umich') }

  before do
    Section.destroy_all
    described_class.destroy_all
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

  context "after destroy" do
    let(:monograph) { create(:monograph) }
    let(:section) { create(:section, monograph_id: monograph.id) }
    before do
      monograph.ordered_members << section
      monograph.save!
    end
    it "has no sections" do
      monograph.destroy
      expect { section.reload }.to raise_error ActiveFedora::ObjectNotFoundError
    end
  end
end
