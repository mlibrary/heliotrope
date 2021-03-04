# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Institution, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, entity_id: entity_id) }

  let(:id) { 1 }
  let(:identifier) { 'identifier' }
  let(:name) { 'name' }
  let(:entity_id) { 'entity_id' }

  before { clear_grants_table }

  it { is_expected.to be_a Greensub::Licensee }
  it { expect(subject.agent_type).to eq :Institution }
  it { expect(subject.agent_id).to eq id }

  describe '#shibboleth?' do
    it { expect(subject.shibboleth?).to be true }

    context 'nil' do
      let(:entity_id) { nil }

      it { expect(subject.shibboleth?).to be false }
    end

    context 'blank' do
      let(:entity_id) { '' }

      it { expect(subject.shibboleth?).to be false }
    end
  end

  context 'before validation' do
    it 'on update' do
      institution = create(:institution, identifier: identifier)
      institution.identifier = 'new_identifier'
      expect(institution.save).to be false
      expect(institution.errors.count).to eq 1
      expect(institution.errors.first[0]).to eq :identifier
      expect(institution.errors.first[1]).to eq "institution identifier can not be changed!"
    end
  end

  context 'before destroy' do
    let(:institution) { create(:institution) }
    let(:product) { create(:product) }
    let(:component) { create(:component) }

    it 'grant present' do
      Authority.grant!(institution, Checkpoint::Credential::Permission.new(:read), component)
      expect(institution.destroy).to be false
      expect(institution.errors.count).to eq 1
      expect(institution.errors.first[0]).to eq :base
      expect(institution.errors.first[1]).to eq "institution has associated grant!"
    end
  end

  context 'other' do
    before { allow(described_class).to receive(:find).with(id).and_return(subject) }

    it 'grants' do
      product = create(:product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      subject.update_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      subject.delete_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    context 'products and components' do
      subject { create(:institution, identifier: identifier, name: name, entity_id: entity_id) }

      let(:product_1) { create(:product, identifier: 'product_1') }
      let(:component_a) { create(:component, identifier: 'component_a') }
      let(:product_2) { create(:product, identifier: 'product_2') }
      let(:component_b) { create(:component, identifier: 'component_b') }

      before do
        subject
        allow(described_class).to receive(:find).with(subject.id).and_return(subject)
      end

      it do
        expect(subject.products.count).to be_zero

        product_1.components << component_a
        expect(subject.products.count).to eq 0

        product_2

        subject.update_product_license(product_2)
        expect(subject.products.count).to eq 1

        product_2.components << component_b
        expect(subject.products.count).to eq 1

        subject.update_product_license(product_1)
        expect(subject.products.count).to eq 2

        product_1.components << component_b
        expect(subject.products.count).to eq 2

        clear_grants_table
        expect(subject.products.count).to eq 0

        Authority.grant!(subject, Checkpoint::Credential::Permission.new(:read), component_b)
        expect(subject.products.count).to eq 0

        Authority.grant!(subject, Checkpoint::Credential::Permission.new(:read), component_a)
        expect(subject.products.count).to eq 0

        clear_grants_table
        expect(subject.products.count).to eq 0
      end
    end
  end
end
