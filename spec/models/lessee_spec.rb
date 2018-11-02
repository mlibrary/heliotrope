# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lessee, type: :model do
  subject { described_class.new(id: id, identifier: "identifier") }

  let(:id) { 1 }
  let(:identifier) { double('identifier') }

  it 'before validation' do
    lessee = create(:lessee, identifier: identifier)
    lessee.identifier = 'new_identifier'
    expect(lessee.save).to be false
    expect(lessee.errors.count).to eq 1
    expect(lessee.errors.first[0]).to eq :identifier
    expect(lessee.errors.first[1]).to eq "lessee identifier can not be changed!"
  end

  context 'before destroy' do
    let(:lessee) { create(:lessee) }
    let(:product) { create(:product) }

    it 'product present' do
      lessee.products << product
      expect(lessee.destroy).to be false
      expect(lessee.errors.count).to eq 1
      expect(lessee.errors.first[0]).to eq :base
      expect(lessee.errors.first[1]).to eq "lessee has 1 associated products!"
    end
  end

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

    context 'non-institution' do
      before { create(:lessee, identifier: identifier) }

      it do
        expect(subject.institution?).to be false
        expect(subject.individual?).to be false
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'institution' do
      before { create(:institution, identifier: identifier) }

      it do
        expect(subject.institution?).to be true
        expect(subject.individual?).to be false
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end

  describe '#individual? and individual' do
    subject { Lessee.find_by(identifier: identifier) }

    let(:identifier) { 'identifier' }

    context 'non-individual' do
      before { create(:lessee, identifier: identifier) }

      it do
        expect(subject.individual?).to be false
        expect(subject.institution?).to be false
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'individual' do
      before { create(:individual, identifier: identifier) }

      it do
        expect(subject.individual?).to be true
        expect(subject.institution?).to be false
        expect(subject.update?).to be false
        expect(subject.destroy?).to be false
      end
    end
  end
end
