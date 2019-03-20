# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, noid: noid) }

  let(:id) { 1 }
  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:noid) { double('noid') }
  let(:handle) { double('handle') }

  it { expect(subject.resource_type).to eq :Component }
  it { expect(subject.resource_id).to eq id }

  context 'before destroy' do
    let(:component) { create(:component) }
    let(:product) { create(:product) }
    let(:individual) { create(:individual) }

    it 'product present' do
      component.products << product
      expect(component.destroy).to be false
      expect(component.errors.count).to eq 1
      expect(component.errors.first[0]).to eq :base
      expect(component.errors.first[1]).to eq "component has 1 associated products!"
    end

    it 'grants present' do
      Greensub.subscribe(individual, component)
      expect(component.destroy).to be false
      expect(component.errors.count).to eq 1
      expect(component.errors.first[0]).to eq :base
      expect(component.errors.first[1]).to eq "component has at least one associated grant!"
    end
  end

  context 'methods' do
    before do
      clear_grants_table
      allow(Component).to receive(:find).with(id).and_return(subject)
    end

    it do
      is_expected.to be_valid
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    it 'products and not_products' do
      n = 3
      products = []
      n.times { |i| products << create(:product, identifier: "product#{i}") }

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true

      products.each_with_index do |product, index|
        expect(subject.products.count).to eq(index)
        expect(subject.not_products.count).to eq(n - index)
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
        subject.products.delete(product)
        subject.save!
      end

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
    end

    context 'noid' do
      before { allow(Sighrax).to receive(:factory).with(noid.to_s).and_return(Sighrax::Model.send(:new, noid, {})) }

      it do
        expect(subject.noid).to eq noid.to_s
        expect(subject.monograph?).to be false
        expect(subject.file_set?).to be false
      end

      context '#monograph?' do
        before { allow(Sighrax).to receive(:factory).with(noid.to_s).and_return(Sighrax::Monograph.send(:new, noid, {})) }

        it do
          expect(subject.noid).to eq noid.to_s
          expect(subject.monograph?).to be true
          expect(subject.file_set?).to be false
        end
      end

      context '#file_set?' do
        before { allow(Sighrax).to receive(:factory).with(noid.to_s).and_return(Sighrax::Asset.send(:new, noid, {})) }

        it do
          expect(subject.noid).to eq noid.to_s
          expect(subject.monograph?).to be false
          expect(subject.file_set?).to be true
        end
      end
    end

    it '#grants?' do
      individual = create(:individual)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      Greensub.subscribe(individual, subject)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Greensub.unsubscribe(individual, subject)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end
  end
end
