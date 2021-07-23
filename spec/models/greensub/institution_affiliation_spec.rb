# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::InstitutionAffiliation, type: :model do
  subject { institution_affiliation }

  let(:institution_affiliation) { described_class.create!(params) }
  let(:params) { { institution_id: institution.id, dlps_institution_id: dlps_institution_id, affiliation: affiliation } }
  let(:institution) { create(:institution) }
  let(:dlps_institution_id) { 1 }
  let(:affiliation) { 'member' }

  describe '#affiliations' do
    it { expect(described_class.affiliations).to contain_exactly('member', 'alum', 'walk-in') }
  end

  describe 'validations' do
    it 'when valid params' do
      expect { subject }.not_to raise_error
    end

    context 'when institution_id blank' do
      let(:institution) { instance_double(Greensub::Institution, 'institution', id: nil) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution must exist, Institution can't be blank") }
    end

    context 'when institution not found' do
      let(:institution) { instance_double(Greensub::Institution, 'institution', id: 1) }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Institution must exist") }
    end

    context 'when dlps institution id blank' do
      let(:dlps_institution_id) { nil }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Dlps institution can't be blank") }
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

  it 'belongs to institution' do
    subject
    expect(Greensub::Institution.count).to eq 1
    expect(Greensub::InstitutionAffiliation.count).to eq 1
    expect { institution.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError, "Cannot delete record because of dependent institution_affiliations")
    institution_affiliation.destroy
    expect(Greensub::InstitutionAffiliation.count).to eq 0
    expect(Greensub::Institution.count).to eq 1
    institution.destroy
    expect(Greensub::Institution.count).to eq 0
  end
end
