# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { described_class.new(identifier: identifier, name: name, purchase: purchase) }

  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:purchase) { double('purchase') }

  it do
    is_expected.to be_valid
    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'components and not_components' do
    n = 3
    components = []
    n.times { |i| components << create(:component, handle: "component#{i}") }

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    components.each_with_index do |component, index|
      expect(subject.components.count).to eq(index)
      expect(subject.not_components.count).to eq(n - index)
      subject.components << component
      subject.save!
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
    end

    components.each_with_index do |component, index|
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.components.count).to eq(n - index)
      expect(subject.not_components.count).to eq(index)
      subject.components.delete(component)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'lessees and not_lessees' do
    n = 3
    lessees = []
    n.times { |i| lessees << create(:lessee, identifier: "lessee#{i}") }

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    lessees.each_with_index do |lessee, index|
      expect(subject.lessees.count).to eq(index)
      expect(subject.not_lessees.count).to eq(n - index)
      subject.lessees << lessee
      subject.save!
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
    end

    lessees.each_with_index do |lessee, index|
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.lessees.count).to eq(n - index)
      expect(subject.not_lessees.count).to eq(index)
      subject.lessees.delete(lessee)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end
end
