# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lessee, type: :model do
  subject { lessee }

  let(:lessee) { described_class.new(identifier: "identifier") }
  let(:identifier) { double('identifier') }

  it { is_expected.to be_valid }

  it 'products and components' do
    n = 3
    products = []
    n.times { products << create(:product) }
    components = []
    n.times { components << create(:component) }
    expected_components = []

    products.each_with_index do |product, index|
      expect(lessee.products.count).to eq(index)
      expect(lessee.not_products.count).to eq(n - index)
      expect(lessee.components).to eq(expected_components)
      expected_components << components[index]
      product.components << components[index]
      product.save!
      lessee.products << product
      lessee.save!
    end

    products.each_with_index do |product, index|
      expect(lessee.products.count).to eq(n - index)
      expect(lessee.not_products.count).to eq(index)
      expect(lessee.components).to eq(expected_components)
      expected_components.delete(components[index])
      lessee.products.delete(product)
      lessee.save!
    end
  end
end
