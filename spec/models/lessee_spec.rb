# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lessee, type: :model do
  subject { described_class.new(identifier: "identifier") }

  let(:identifier) { double('identifier') }

  it do
    is_expected.to be_valid
    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'products, not_products, and components' do
    n = 3
    products = []
    n.times { |i| products << create(:product, identifier: "product#{i}") }
    components = []
    n.times { |i| components << create(:component, handle: "component#{i}") }
    expected_components = []

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    products.each_with_index do |product, index|
      expect(subject.products.count).to eq(index)
      expect(subject.not_products.count).to eq(n - index)
      expect(subject.components).to eq(expected_components)
      expected_components << components[index]
      product.components << components[index]
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
      expect(subject.components).to eq(expected_components)
      expected_components.delete(components[index])
      subject.products.delete(product)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  describe '#institution? and institution' do
    subject { Lessee.find_by(identifier: identifier) }

    let(:identifier) { 'identifier' }

    context 'non-instituion' do
      before { create(:lessee, identifier: identifier) }

      it do
        expect(subject.institution?).to be false
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'institution' do
      before { create(:institution, identifier: identifier) }

      it do
        expect(subject.institution?).to be true
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
