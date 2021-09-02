# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::License, type: :model do
  let(:individual) { create(:individual) }
  let(:institution) { create(:institution) }
  let(:product) { create(:product) }

  describe 'Individual Full License' do
    subject { license }

    let(:license) { create(:full_license, licensee: individual, product: product) }

    it { expect { subject }.not_to raise_exception }
    it { expect(subject).to be_an_instance_of(Greensub::FullLicense) }
    it { expect(subject.label).to eq 'Full' }
    it { expect(subject.entitlements).to contain_exactly(:download, :reader) }
    it { expect(subject.allows?(:action)).to be false }
    it { expect(subject.allows?(:download)).to be true }
    it { expect(subject.allows?(:reader)).to be true }
    it { expect(subject.update?).to be true }
    it { expect(subject.destroy?).to be true }
    it { expect(subject.credential_id).to eq license.id }
    it { expect(subject.credential_type).to be :License }
    it { expect(subject.to_credential).to be_an_instance_of(Greensub::LicenseCredential) }
    it { expect(subject.licensee).to eq individual }
    it { expect(subject.product).to eq product }

    it 'update type' do
      subject.type = 'Greensub::ReadLicense'
      expect { subject.save! }.not_to raise_exception
    end

    it 'update licensee' do
      subject.licensee = create(:individual)
      expect { subject.save! }.to raise_exception(ActiveRecord::RecordInvalid, 'Validation failed: Licensee can not be changed!')
    end

    it 'update product' do
      subject.product = create(:product)
      expect { subject.save! }.to raise_exception(ActiveRecord::RecordInvalid, 'Validation failed: Product can not be changed!')
    end

    it 'destroy' do
      expect(subject.destroy).to be subject
      expect(subject.errors.count).to eq 0
      expect(Greensub::License.count).to eq 0
    end

    context 'with grant' do
      before do
        clear_grants_table
        Authority.grant!(individual, license, product)
      end

      it { expect(subject.update?).to be false }
      it { expect(subject.destroy?).to be false }

      it 'update type' do
        subject.type = 'Greensub::ReadLicense'
        expect { subject.save! }.not_to raise_exception
      end

      it 'destroy fails' do
        expect(subject.destroy).to be false
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first[0]).to eq :base
        expect(subject.errors.first[1]).to eq "Cannot delete record because dependent grant exist"
      end
    end
  end

  describe 'Institution Read License' do
    subject { license }

    let(:license) { create(:read_license, licensee: institution, product: product) }

    it { expect { subject }.not_to raise_exception }
    it { expect(subject).to be_an_instance_of(Greensub::ReadLicense) }
    it { expect(subject.label).to eq 'Read' }
    it { expect(subject.entitlements).to contain_exactly(:reader) }
    it { expect(subject.allows?(:action)).to be false }
    it { expect(subject.allows?(:download)).to be false }
    it { expect(subject.allows?(:reader)).to be true }
    it { expect(subject.update?).to be true }
    it { expect(subject.destroy?).to be true }
    it { expect(subject.credential_id).to eq license.id }
    it { expect(subject.credential_type).to be :License }
    it { expect(subject.to_credential).to be_an_instance_of(Greensub::LicenseCredential) }
    it { expect(subject.licensee).to eq institution }
    it { expect(subject.product).to eq product }

    it 'update type' do
      subject.type = 'Greensub::FullLicense'
      expect { subject.save! }.not_to raise_exception
    end

    it 'update licensee' do
      subject.licensee = create(:institution)
      expect { subject.save! }.to raise_exception(ActiveRecord::RecordInvalid, 'Validation failed: Licensee can not be changed!')
    end

    it 'update product' do
      subject.product = create(:product)
      expect { subject.save! }.to raise_exception(ActiveRecord::RecordInvalid, 'Validation failed: Product can not be changed!')
    end

    it 'destroy' do
      expect(subject.destroy).to be subject
      expect(subject.errors.count).to eq 0
      expect(Greensub::License.count).to eq 0
    end

    context 'with grant' do
      before do
        clear_grants_table
        Authority.grant!(institution, license, product)
      end

      it { expect(subject.update?).to be false }
      it { expect(subject.destroy?).to be false }

      it 'update type' do
        subject.type = 'Greensub::FullLicense'
        expect { subject.save! }.not_to raise_exception
      end

      it 'destroy fails' do
        expect(subject.destroy).to be false
        expect(subject.errors.count).to eq 1
        expect(subject.errors.first[0]).to eq :base
        expect(subject.errors.first[1]).to eq "Cannot delete record because dependent grant exist"
      end
    end
  end
end
