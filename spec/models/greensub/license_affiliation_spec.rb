# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::LicenseAffiliation, type: :model do
  subject { license_affiliation }

  let(:license_affiliation) { described_class.create!(params) }
  let(:params) { { license_id: license.id, affiliation: affiliation } }
  let(:license) { create(:full_license, licensee: licensee, product: product) }
  let(:licensee) { create(:individual) }
  let(:product) { create(:product) }
  let(:affiliation) { 'member' }

  describe '#affiliations' do
    it { expect(described_class.affiliations).to contain_exactly('member', 'alum', 'walk-in') }
  end

  describe 'validations' do
    it 'when valid params' do
      expect { subject }.not_to raise_error
    end

    context 'when license_id blank' do
      let(:license) { instance_double(Greensub::License, 'license', id: nil) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: License must exist, License can't be blank") }
    end

    context 'when license not found' do
      let(:license) { instance_double(Greensub::License, 'license', id: 1) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: License must exist") }
    end

    context 'when affiliation blank' do
      let(:affiliation) { '' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Affiliation can't be blank, Affiliation is not included in the list") }
    end

    context 'when affiliation not included in list' do
      let(:affiliation) { 'Member' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Affiliation is not included in the list") }
    end
  end

  it 'belongs to license' do
    subject
    expect(Greensub::License.count).to eq 1
    expect(Greensub::LicenseAffiliation.count).to eq 1
    expect(license.destroy).to be false
    expect(license.errors.count).to eq 1
    expect(license.errors.first[0]).to eq :base
    expect(license.errors.first[1]).to eq "Cannot delete record because dependent license affiliations exist"
    license_affiliation.destroy
    expect(Greensub::LicenseAffiliation.count).to eq 0
    expect(Greensub::License.count).to eq 1
    license.destroy
    expect(Greensub::License.count).to eq 0
  end
end
