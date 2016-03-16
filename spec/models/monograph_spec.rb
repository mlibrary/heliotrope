require 'rails_helper'

describe Monograph do
  let(:instance) { described_class.new }
  let(:date) { DateTime.now }

  it "has date_published" do
    instance.date_published = [date]
    expect(instance.date_published).to eq [date]
  end
end
