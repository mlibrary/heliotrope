# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, noid: noid, handle: handle) }

  let(:id) { 1 }
  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:noid) { double('noid') }
  let(:handle) { double('handle') }

  before do
    PermissionService.clear_permits_table
    allow(Component).to receive(:find).with(id).and_return(subject)
  end

  context 'before destroy' do
    let(:component) { create(:component) }
    let(:product) { create(:product) }
    let(:policy) { double('policy') }

    before { allow(Policy).to receive(:resource_policies).with(component).and_return([policy]) }

    it 'product present' do
      component.products << product
      expect(component.destroy).to be false
      expect(component.errors.count).to eq 1
      expect(component.errors.first[0]).to eq :base
      expect(component.errors.first[1]).to eq "component has 1 associated products!"
    end

    it 'policies present' do
      expect(component.destroy).to be false
      expect(component.errors.count).to eq 1
      expect(component.errors.first[0]).to eq :base
      expect(component.errors.first[1]).to eq "component has 1 associated policies!"
    end
  end

  it do
    is_expected.to be_valid
    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
  end

  it 'products, not_products and lessees' do # TODO: Remove lessees
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

  context 'noid' do
    let(:noid_service) { double('noid_service', type: type) }
    let(:type) { NoidService.null_object.type }

    before { allow(NoidService).to receive(:from_noid).with(noid.to_s).and_return(noid_service) }

    it do
      expect(subject.noid).to eq noid.to_s
      expect(subject.monograph?).to be false
      expect(subject.file_set?).to be false
    end

    context 'monograph' do
      let(:type) { :monograph }

      it do
        expect(subject.monograph?).to be true
        expect(subject.file_set?).to be false
      end

      context 'file_set' do
        let(:type) { :file_set }

        it do
          expect(subject.monograph?).to be false
          expect(subject.file_set?).to be true
        end
      end
    end
  end

  it 'policies' do
    permission_service = PermissionService.new

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.policies.first).to be nil

    permit = permission_service.permit_open_access_resource(described_class, subject.id)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.policies.first.permit).to eq permit

    permission_service.revoke_open_access_resource(described_class, subject.id)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.policies.first).to be nil
  end
end
