# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, purchase: purchase) }

  let(:id) { 1 }
  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:purchase) { double('purchase') }

  it { expect(subject.resource_type).to eq :Product }
  it { expect(subject.resource_id).to eq id }

  context 'before destroy' do
    let(:product) { create(:product) }
    let(:component) { create(:component) }

    it 'component present' do
      product.components << component
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has 1 associated components!"
    end

    it 'grants present' do
      individual = create(:individual)
      Greensub.subscribe(subscriber: individual, target: product)
      expect(product.destroy).to be false
      expect(product.errors.count).to eq 1
      expect(product.errors.first[0]).to eq :base
      expect(product.errors.first[1]).to eq "product has at least one associated grant!"
    end
  end

  context 'methods' do
    before do
      clear_grants_table
      allow(Product).to receive(:find).with(id).and_return(subject)
    end

    it do
      is_expected.to be_valid
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    it 'components and not_components' do
      n = 3
      components = []
      n.times { components << create(:component) }

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

    it '#grants?' do
      individual = create(:individual)
      institution = create(:institution)
      expect(subject.subscribers).to be_empty

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      Greensub.subscribe(subscriber: individual, target: subject)
      expect(subject.subscribers).to match_array([individual])

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Greensub.subscribe(subscriber: institution, target: subject)
      expect(subject.subscribers).to match_array([individual, institution])

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Greensub.unsubscribe(subscriber: individual, target: subject)
      expect(subject.subscribers).to match_array([institution])

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      Greensub.unsubscribe(subscriber: institution, target: subject)
      expect(subject.subscribers).to be_empty

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end
  end
end
