# frozen_string_literal: true

require 'rails_helper'

describe DlpsInstitution do
  describe '#find' do
    subject { described_class.new.find(request_attributes) }

    let(:request_attributes) { {} }

    it { is_expected.to eq [] }

    context 'request_attributes' do
      let(:request_attributes) { { dlpsInstitutionId: ids, identity_provider: entity_id } }
      let(:ids) { }
      let(:entity_id) { }

      it { is_expected.to eq [] }

      context 'institutions' do
        let(:institution_1) { create(:institution, identifier: '1', entity_id: 'entity_1') }
        let!(:institution_1_affiliation_1) { create(:institution_affiliation, institution_id: institution_1.id, dlps_institution_id: institution_1.identifier, affiliation: 'member') }
        let(:institution_2) { create(:institution, identifier: '2', entity_id: 'entity_2') }
        let!(:institution_2_affiliation_1) { create(:institution_affiliation, institution_id: institution_2.id, dlps_institution_id: institution_2.identifier, affiliation: 'member') }

        context 'ip_based' do
          let(:ids) { [institution_2.identifier] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution_2] }
        end

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to eq [institution_1] }
        end

        context 'both' do
          let(:ids) { [institution_1.identifier, institution_2.identifier] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to eq [institution_1, institution_2] }
        end
      end

      context "HELIO-4210: Johns Hopkins University" do
        let(:institution) { create(:institution, identifier: '296', name: 'Johns Hopkins University', entity_id: 'urn:mace:incommon:johnshopkins.edu') }
        let(:affiliation_1) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '296', affiliation: 'member') }
        let(:affiliation_2) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '296', affiliation: 'walk-in') }
        let(:affiliation_3) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: '2395', affiliation: 'alum') }

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution.entity_id }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, alum' do
          let(:ids) { [affiliation_3.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, member' do
          let(:ids) { [affiliation_1.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end

        context 'ip based, multiple dlps ids' do
          let(:ids) { [affiliation_1.dlps_institution_id, affiliation_3.dlps_institution_id] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to eq [institution] }
        end
      end
    end
  end
end
