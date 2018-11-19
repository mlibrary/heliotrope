# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, purchase: purchase) }

  let(:id) { 1 }
  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:purchase) { double('purchase') }

  before do
    PermissionService.clear_permits_table
    allow(Product).to receive(:find).with(id).and_return(subject)
  end

  it { expect(subject.resource_type).to eq :Product }
  it { expect(subject.resource_id).to eq id }

  context 'before destroy' do
    let(:product) { create(:product) }
    let(:component) { create(:component) }
    let(:lessee) { create(:lessee) }
    let(:grant) { double('grant') }

    before { allow(Grant).to receive(:resource_grants).with(product).and_return([grant]) }

    it 'component present' do
      product.components << component
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has 1 associated components!"
    end

    it 'lessee present' do
      product.lessees << lessee
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has 1 associated lessees!"
    end

    it 'grants present' do
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has 1 associated grants!"
    end
  end

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

  it 'individuals' do
    n = 3
    individuals = []
    n.times { |i| individuals << create(:individual, identifier: "individual#{i}") }

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    individuals.each_with_index do |individual, index|
      expect(subject.individuals.count).to eq(index)
      subject.lessees << individual.lessee
      subject.save!
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
    end

    individuals.each_with_index do |individual, index|
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.individuals.count).to eq(n - index)
      subject.lessees.delete(individual.lessee)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'institutions' do
    n = 3
    institutions = []
    n.times { |i| institutions << create(:institution, identifier: "institution#{i}") }

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true

    institutions.each_with_index do |institution, index|
      expect(subject.institutions.count).to eq(index)
      subject.lessees << institution.lessee
      subject.save!
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
    end

    institutions.each_with_index do |institution, index|
      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.institutions.count).to eq(n - index)
      subject.lessees.delete(institution.lessee)
      subject.save!
    end

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'grants' do
    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.grants.first).to be nil

    permit = PermissionService.permit_open_access_resource(described_class, subject.id)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants.first.permit).to eq permit

    PermissionService.revoke_open_access_resource(described_class, subject.id)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.grants.first).to be nil
  end
end
