# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lessee, type: :model do
  subject { lessee }

  let(:lessee) { described_class.new(identifier: "identifier") }
  let(:identifier) { double('identifier') }

  it { is_expected.to be_valid }

  it 'products, not_products, and components' do
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

  describe '#grouping? and grouping' do
    subject { lessee.grouping? }

    let(:lessee) { Lessee.find_by(identifier: identifier) }
    let(:identifier) { 'identifier' }

    context 'not-grouping' do
      before { create(:lessee, identifier: identifier) }

      it { is_expected.to be false }
    end

    context 'grouping' do
      before { create(:grouping, identifier: identifier) }

      it { is_expected.to be true }
    end
  end

  it 'groupings and not_groupings' do
    n = 3
    groupings = []
    n.times { |i| groupings << create(:grouping, identifier: "grouping#{i}") }
    expected_groupings = []

    groupings.each_with_index do |grouping, index|
      expect(lessee.groupings.count).to eq(index)
      expect(lessee.not_groupings.count).to eq(n - index)
      expect(lessee.groupings).to eq(expected_groupings)
      expected_groupings << grouping
      lessee.groupings << grouping
      lessee.save!
    end

    groupings.each_with_index do |grouping, index|
      expect(lessee.groupings.count).to eq(n - index)
      expect(lessee.not_groupings.count).to eq(index)
      expect(lessee.groupings).to eq(expected_groupings)
      expected_groupings.delete(grouping)
      lessee.groupings.delete(grouping)
      lessee.save!
    end
  end

  describe '#institution? and institution' do
    subject { lessee.institution? }

    let(:lessee) { Lessee.find_by(identifier: identifier) }
    let(:identifier) { 'identifier' }

    before { create(:lessee, identifier: identifier) }

    context 'non-instituion' do
      it { is_expected.to be false }
    end

    context 'institution' do
      before { create(:institution, identifier: identifier) }

      it { is_expected.to be true }
    end
  end
end
