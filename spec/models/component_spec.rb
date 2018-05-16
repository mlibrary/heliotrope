# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { described_class.new(handle: "handle") }

  let(:handle) { double('handle') }

  it do
    is_expected.to be_valid
    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'products, not_products, and lessees' do
    n = 3
    products = []
    n.times { |i| products << create(:product, identifier: "product#{i}") }
    lessees = []
    n.times { |i| lessees << create(:lessee, identifier: "lessee#{i}") }
    expected_lessees = []

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    products.each_with_index do |product, index|
      expect(subject.products.count).to eq(index)
      expect(subject.not_products.count).to eq(n - index)
      expect(subject.lessees).to eq(expected_lessees)
      expected_lessees << lessees[index]
      product.lessees << lessees[index]
      product.save!
      subject.products << product
      subject.save!
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
    end

    products.each_with_index do |product, index|
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.products.count).to eq(n - index)
      expect(subject.not_products.count).to eq(index)
      expect(subject.lessees).to eq(expected_lessees)
      expected_lessees.delete(lessees[index])
      subject.products.delete(product)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'lessees recursive' do
    n = 3
    product = create(:product)
    n.times { |i| product.lessees << create(:lessee, identifier: "product_lessee#{i}") }
    grouping = create(:grouping, identifier: 'grouping')
    n.times { |i| grouping.lessees << create(:lessee, identifier: "grouping_lessee#{i}") }
    product.lessees << grouping.lessee
    product.save!
    subject.products << product
    subject.save!
    expected_lessees = []
    product.lessees.each { |l| expected_lessees << l }
    grouping.lessees.each { |l| expected_lessees << l }
    expect(subject.lessees(true)).to eq(expected_lessees)
  end
end
