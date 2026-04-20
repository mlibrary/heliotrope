# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterSummary, type: :model do
  it 'requires press_id' do
    expect(described_class.new(year: 2024, month: 1)).not_to be_valid
  end

  it 'requires year' do
    expect(described_class.new(press_id: 1, month: 1)).not_to be_valid
  end

  it 'requires month' do
    expect(described_class.new(press_id: 1, year: 2024)).not_to be_valid
  end
end
