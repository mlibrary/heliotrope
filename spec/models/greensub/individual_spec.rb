# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Individual, type: :model do
  context 'instance' do
    subject { described_class.new(id: id, identifier: identifier, name: name, email: email) }

    let(:id) { 1 }
    let(:identifier) { 'identifier' }
    let(:name) { 'name' }
    let(:email) { 'email' }

    it { is_expected.to be_a Greensub::Licensee }
    it { expect(subject.agent_type).to eq :Individual }
    it { expect(subject.agent_id).to eq id }
  end

  context 'before validation' do
    it 'on update' do
      individual = create(:individual)
      individual.identifier = 'new_identifier'
      expect(individual.save).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :identifier
      expect(individual.errors.first[1]).to eq "individual identifier can not be changed!"
    end
  end

  context 'before destroy' do
    let(:individual) { create(:individual) }
    let(:product) { create(:product) }
    let(:license) { create(:full_license, licensee: individual, product: product) }

    it 'license present' do
      license
      expect(individual.destroy).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :base
      expect(individual.errors.first[1]).to eq "Cannot delete record because dependent licenses exist"
    end
  end

  context 'methods' do
    subject { individual }

    let(:individual) { create(:individual) }

    before { clear_grants_table }

    it do
      is_expected.to be_valid
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    it 'grants' do
      product = create(:product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      subject.create_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      subject.delete_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    context 'products and components' do
      subject { create(:individual) }

      let(:product_1) { create(:product, identifier: 'product_1') }
      let(:component_a) { create(:component, identifier: 'component_a') }
      let(:product_2) { create(:product, identifier: 'product_2') }
      let(:component_b) { create(:component, identifier: 'component_b') }

      it do
        expect(subject.products.count).to be_zero

        product_1.components << component_a
        expect(subject.products.count).to eq 0

        product_2

        subject.create_product_license(product_2)
        expect(subject.products.count).to eq 1

        product_2.components << component_b
        expect(subject.products.count).to eq 1

        subject.create_product_license(product_1)
        expect(subject.products.count).to eq 2

        product_1.components << component_b
        expect(subject.products.count).to eq 2
      end
    end
  end
end
