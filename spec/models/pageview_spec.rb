require 'rails_helper'

describe Pageview, type: :model do
  it 'has a pageviews metric' do
    expect(described_class.metrics).to be == Legato::ListParameter.new(:metrics, [:pageviews])
  end

  it 'has a date and pagePath dimension' do
    expect(described_class.dimensions).to be == Legato::ListParameter.new(:dimensions, [:date, :pagePath])
  end
end
