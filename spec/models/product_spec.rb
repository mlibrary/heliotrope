# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { product }

  let(:product) { described_class.new(identifier: identifier, purchase: purchase) }
  let(:identifier) { double('identifier') }
  let(:purchase) { double('purchase') }

  it { is_expected.to be_valid }

  it 'components' do
    n = 3
    components = []
    n.times { components << create(:component) }

    components.each_with_index do |component, index|
      expect(product.components.count).to eq(index)
      expect(product.not_components.count).to eq(n - index)
      product.components << component
      product.save!
    end

    components.each_with_index do |component, index|
      expect(product.components.count).to eq(n - index)
      expect(product.not_components.count).to eq(index)
      product.components.delete(component)
      product.save!
    end
  end

  it 'lessees' do
    n = 3
    lessees = []
    n.times { lessees << create(:lessee) }

    lessees.each_with_index do |lessee, index|
      expect(product.lessees.count).to eq(index)
      expect(product.not_lessees.count).to eq(n - index)
      product.lessees << lessee
      product.save!
    end

    lessees.each_with_index do |lessee, index|
      expect(product.lessees.count).to eq(n - index)
      expect(product.not_lessees.count).to eq(index)
      product.lessees.delete(lessee)
      product.save!
    end
  end
end
