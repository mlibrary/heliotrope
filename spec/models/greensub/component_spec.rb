# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Component, type: :model do
  subject { component }

  let(:component) { described_class.create!(params) }
  let(:params) { { identifier: identifier, name: name, noid: noid } }
  let(:identifier) { 'identifier' }
  let(:name) { 'name' }
  let(:noid) { 'validnoid' }

  it 'instance' do
    expect { subject }.not_to raise_error
    expect(subject.resource_type).to eq :Component
    expect(subject.resource_id).to eq subject.id

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.grants?).to be false
  end

  describe 'validations' do
    context 'when identifier blank' do
      let(:identifier) { '' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Identifier can't be blank") }
    end

    context 'when identifier not unique' do
      before { subject }

      it { expect { described_class.create!(params) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Identifier has already been taken") }
    end

    context 'when name blank' do
      let(:name) { '' }

      it { expect { subject }.not_to raise_error }
    end

    context 'when noid blank' do
      let(:noid) { '' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Noid can't be blank") }
    end
  end

  describe 'destroy' do
    let(:product) { create(:product) }
    let(:individual) { create(:individual) }

    it { expect(subject.destroy).to be component }
    it { expect { subject.destroy! }.not_to raise_exception }

    it 'when product present' do
      subject.products << product
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "Cannot delete record because dependent components products exist"
    end

    it 'when grant present' do
      clear_grants_table
      Authority.grant!(individual, Checkpoint::Credential::Permission.new(:read), subject)
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "Cannot delete record because dependent grant exist"
    end
  end

  describe "reindex file set" do
    let(:product) { create(:product) }

    it "adding a product runs the ReindexJob" do
      expect(subject.products).to be_empty
      allow(ReindexJob).to receive(:perform_later).with(subject.noid)
      subject.products << product
      expect(ReindexJob).to have_received(:perform_later).with(subject.noid)
      expect(subject.products.count).to eq 1
    end

    it "deleting a product runs the ReindexJob" do
      subject.products << product
      expect(subject.products.count).to eq 1
      allow(ReindexJob).to receive(:perform_later).with(subject.noid)
      subject.products.delete(product)
      expect(ReindexJob).to have_received(:perform_later).with(subject.noid)
      expect(subject.products).to be_empty
    end
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
    before { allow(Sighrax).to receive(:from_noid).with(noid.to_s).and_return(Sighrax::Model.send(:new, noid, {})) }

    it do
      expect(subject.noid).to eq noid.to_s
      expect(subject.monograph?).to be false
      expect(subject.file_set?).to be false
    end

    context '#monograph?' do
      before { allow(Sighrax).to receive(:from_noid).with(noid.to_s).and_return(Sighrax::Monograph.send(:new, noid, {})) }

      it do
        expect(subject.noid).to eq noid.to_s
        expect(subject.monograph?).to be true
        expect(subject.file_set?).to be false
      end
    end

    context '#file_set?' do
      before { allow(Sighrax).to receive(:from_noid).with(noid.to_s).and_return(Sighrax::Resource.send(:new, noid, {})) }

      it do
        expect(subject.noid).to eq noid.to_s
        expect(subject.monograph?).to be false
        expect(subject.file_set?).to be true
      end
    end
  end

  it 'grants' do
    individual = create(:individual)

    Authority.grant!(individual, Checkpoint::Credential::Permission.new(:read), subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be true

    Authority.revoke!(individual, Checkpoint::Credential::Permission.new(:read), subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.grants?).to be false
  end
end
