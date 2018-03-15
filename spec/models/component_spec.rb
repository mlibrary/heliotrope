# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { component }

  let(:component) { described_class.new(handle: "handle") }
  let(:handle) { double('handle') }

  it { is_expected.to be_valid }

  it 'products and lessees' do
    n = 3
    products = []
    n.times { products << create(:product) }
    lessees = []
    n.times { lessees << create(:lessee) }
    expected_lessees = []

    products.each_with_index do |product, index|
      expect(component.products.count).to eq(index)
      expect(component.not_products.count).to eq(n - index)
      expect(component.lessees).to eq(expected_lessees)
      expected_lessees << lessees[index]
      product.lessees << lessees[index]
      product.save!
      component.products << product
      component.save!
    end

    products.each_with_index do |product, index|
      expect(component.products.count).to eq(n - index)
      expect(component.not_products.count).to eq(index)
      expect(component.lessees).to eq(expected_lessees)
      expected_lessees.delete(lessees[index])
      component.products.delete(product)
      component.save!
    end
  end
end
