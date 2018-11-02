# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Individual, type: :model do
  subject { described_class.new(id: id, identifier: identifier, name: name, email: email) }

  let(:id) { 1 }
  let(:identifier) { 'identifier' }
  let(:name) { 'name' }
  let(:email) { 'email' }

  before do
    PermissionService.clear_permits_table
    allow(described_class).to receive(:find).with(id).and_return(subject)
  end

  context 'before validation' do
    it 'on create' do
      create(:lessee, identifier: identifier)
      individual = build(:individual, identifier: identifier)
      expect(individual.save).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :identifier
      expect(individual.errors.first[1]).to eq "lessee identifier identifier exists!"
    end
    it 'on update' do
      individual = create(:individual, identifier: identifier)
      individual.identifier = 'new_identifier'
      expect(individual.save).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :identifier
      expect(individual.errors.first[1]).to eq "individual identifier can not be changed!"
    end
  end

  context 'before create' do
    it do
      create(:lessee, identifier: identifier)
      individual = build(:individual, identifier: identifier)
      expect(individual.save(validate: false)).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :identifier
      expect(individual.errors.first[1]).to eq "create lessee identifier fail! Validation failed: Identifier has already been taken"
    end
  end

  context 'before destroy' do
    let(:individual) { create(:individual) }
    let(:product) { create(:product) }
    let(:policy) { double('policy') }

    before { allow(Policy).to receive(:agent_policies).with(individual).and_return([policy]) }

    it 'product present' do
      individual.lessee.products << product
      expect(individual.destroy).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :base
      expect(individual.errors.first[1]).to eq "individual has 1 associated products!"
    end

    it 'policies present' do
      expect(individual.destroy).to be false
      expect(individual.errors.count).to eq 1
      expect(individual.errors.first[0]).to eq :base
      expect(individual.errors.first[1]).to eq "individual has 1 associated policies!"
    end
  end

  describe 'lessee' do
    let(:lessee) { Lessee.find_by(identifier: identifier) }

    context 'build' do
      subject { build(:individual, identifier: identifier, name: name, email: email) }

      it do
        is_expected.to be_valid
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end

      describe '#lessee' do
        it do
          expect(subject.lessee).to be nil
          expect(lessee).to be nil
        end
      end

      context 'saved' do
        before { subject.save }

        it do
          is_expected.to be_valid
          expect(subject.update?).to be true
          expect(subject.destroy?).to be true
        end

        describe '#lessee' do
          it do
            expect(subject.lessee).not_to be nil
            expect(subject.lessee).to eq lessee
          end
        end

        context 'destroy' do
          before { subject.destroy }

          it { expect(lessee).to be nil }
        end
      end
    end

    context 'create' do
      subject { create(:individual, identifier: identifier, name: name, email: email) }

      it do
        is_expected.to be_valid
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end

      describe '#lessee' do
        it do
          expect(subject.lessee).not_to be nil
          expect(subject.lessee).to eq lessee
        end
      end

      context 'destroy' do
        before { subject.destroy }

        it { expect(lessee).to be nil }
      end
    end
  end

  it 'policies' do
    permission_service = PermissionService.new

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.policies.first).to be nil

    permit = permission_service.permit_read_access_resource(described_class, subject.id, :any, :any)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.policies.first.permit).to eq permit

    permission_service.revoke_read_access_resource(described_class, subject.id, :any, :any)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.policies.first).to be nil
  end

  context 'products and components' do
    subject { create(:individual, identifier: identifier, name: name) }

    let(:product_1) { create(:product, identifier: 'product_1') }
    let(:component_a) { create(:component, identifier: 'component_a', handle: 'lessee_handle') }
    let(:product_2) { create(:product, identifier: 'product_2') }
    let(:component_b) { create(:component, identifier: 'component_b', handle: 'policy_handle') }

    before do
      subject
      allow(described_class).to receive(:find).with(subject.id).and_return(subject)
    end

    it do
      expect(subject.products.count).to be_zero
      expect(subject.components.count).to be_zero

      subject.lessee.products << product_1
      expect(subject.products.count).to eq 1
      expect(subject.components.count).to eq 0

      product_1.components << component_a
      expect(subject.products.count).to eq 1
      expect(subject.components.count).to eq 1

      permission_service = PermissionService.new
      product_2

      permission_service.permit_read_access_resource(described_class, subject.id, Product, product_2.id)
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 1

      product_2.components << component_b
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 2

      permission_service.permit_read_access_resource(described_class, subject.id, Product, product_1.id)
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 2

      product_1.components << component_b
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 2

      PermissionService.clear_permits_table
      expect(subject.products.count).to eq 1
      expect(subject.components.count).to eq 2

      subject.lessee.products.delete(product_1)
      expect(subject.products.count).to eq 0
      expect(subject.components.count).to eq 0

      permission_service.permit_read_access_resource(described_class, subject.id, Component, component_b.id)
      expect(subject.products.count).to eq 0
      expect(subject.components.count).to eq 1

      permission_service.permit_read_access_resource(described_class, subject.id, Component, component_a.id)
      expect(subject.products.count).to eq 0
      expect(subject.components.count).to eq 2

      subject.lessee.products << product_2
      expect(subject.products.count).to eq 1
      expect(subject.components.count).to eq 2

      subject.lessee.products << product_1
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 2

      PermissionService.clear_permits_table
      expect(subject.products.count).to eq 2
      expect(subject.components.count).to eq 2

      subject.lessee.products.delete(product_1)
      expect(subject.products.count).to eq 1
      expect(subject.components.count).to eq 1

      subject.lessee.products.delete(product_2)
      expect(subject.products.count).to eq 0
      expect(subject.components.count).to eq 0
    end
  end
end
