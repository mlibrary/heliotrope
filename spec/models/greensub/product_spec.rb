# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Product, type: :model do
  subject { product }

  let(:product) { described_class.create!(params) }
  let(:params) { { identifier: identifier, name: name, purchase: purchase } }
  let(:identifier) { 'identifier' }
  let(:name) { 'name' }
  let(:purchase) { 'purchase' }

  it 'instance' do
    expect { subject }.not_to raise_error
    expect(subject.resource_type).to eq :Product
    expect(subject.resource_id).to eq subject.id

    expect(subject.licensees?).to be false
    expect(subject.licensees).to be_empty
    expect(subject.individuals?).to be false
    expect(subject.individuals).to be_empty
    expect(subject.institutions?).to be false
    expect(subject.institutions).to be_empty
    expect(subject.licenses?).to be false
    expect(subject.licenses).to be_empty

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

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank") }
    end

    context 'when purchase blank' do
      let(:purchase) { '' }

      it { expect { subject }.not_to raise_error }
    end
  end

  describe 'destroy' do
    let(:component) { create(:component) }
    let(:license) { create(:full_license, licensee: individual, product: product) }
    let(:individual) { create(:individual) }

    it { expect(subject.destroy).to be product }
    it { expect { subject.destroy! }.not_to raise_exception }

    it 'when component present' do
      subject.components << component
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "Cannot delete record because dependent components products exist"
    end

    it 'when license present' do
      license
      expect(subject.destroy).to be false
      expect(subject.errors.count).to eq 1
      expect(subject.errors.first[0]).to eq :base
      expect(subject.errors.first[1]).to eq "Cannot delete record because dependent licenses exist"
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
    let(:component) { create(:component) }

    it "adding components runs the ReindexJob" do
      expect(subject.components).to be_empty
      allow(ReindexJob).to receive(:perform_later).with(component.noid)
      subject.components << component
      expect(ReindexJob).to have_received(:perform_later).with(component.noid)
      expect(subject.components.count).to eq 1
    end

    it "deleting components runs the ReindexJob" do
      subject.components << component
      expect(subject.components.count).to eq 1
      allow(ReindexJob).to receive(:perform_later).with(component.noid)
      subject.components.delete(component)
      expect(ReindexJob).to have_received(:perform_later).with(component.noid)
      expect(subject.components).to be_empty
    end
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

  it 'licenses and grants' do
    clear_grants_table
    individual = create(:individual)
    individual_license = create(:full_license, licensee: individual, product: subject)
    subject.reload

    expect(subject.licensees?).to be true
    expect(subject.licensees).to contain_exactly(individual)
    expect(subject.individuals?).to be true
    expect(subject.individuals).to contain_exactly(individual)
    expect(subject.institutions?).to be false
    expect(subject.institutions).to be_empty
    expect(subject.licenses?).to be true
    expect(subject.licenses).to contain_exactly(individual_license)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be false

    institution = create(:institution)
    institution_license = create(:full_license, licensee: institution, product: subject)
    subject.reload

    expect(subject.licensees?).to be true
    expect(subject.licensees).to contain_exactly(individual, institution)
    expect(subject.individuals?).to be true
    expect(subject.individuals).to contain_exactly(individual)
    expect(subject.institutions?).to be true
    expect(subject.institutions).to contain_exactly(institution)
    expect(subject.licenses?).to be true
    expect(subject.licenses).to contain_exactly(individual_license, institution_license)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be false

    Authority.grant!(individual, individual_license, subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be true

    Authority.grant!(institution, institution_license, subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be true

    Authority.revoke!(individual, individual_license, subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be true

    Authority.revoke!(institution, institution_license, subject)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be false

    individual_license.destroy!
    subject.reload

    expect(subject.licensees?).to be true
    expect(subject.licensees).to contain_exactly(institution)
    expect(subject.individuals?).to be false
    expect(subject.individuals).to be_empty
    expect(subject.institutions?).to be true
    expect(subject.institutions).to contain_exactly(institution)
    expect(subject.licenses?).to be true
    expect(subject.licenses).to contain_exactly(institution_license)

    expect(subject.update?).to be true
    expect(subject.destroy?).to be false
    expect(subject.grants?).to be false

    institution_license.destroy!
    subject.reload

    expect(subject.licensees?).to be false
    expect(subject.licensees).to be_empty
    expect(subject.individuals?).to be false
    expect(subject.individuals).to be_empty
    expect(subject.institutions?).to be false
    expect(subject.institutions).to be_empty
    expect(subject.licenses?).to be false
    expect(subject.licenses).to be_empty

    expect(subject.update?).to be true
    expect(subject.destroy?).to be true
    expect(subject.grants?).to be false
  end
end
