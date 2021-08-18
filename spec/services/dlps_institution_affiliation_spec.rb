# frozen_string_literal: true

require 'rails_helper'

describe DlpsInstitutionAffiliation do
  describe '#find' do
    subject { described_class.new.find(request_attributes) }

    let(:request_attributes) { {} }

    it { is_expected.to eq [] }

    context 'request_attributes' do
      let(:request_attributes) { { dlpsInstitutionId: ids, identity_provider: entity_id, eduPersonScopedAffiliation: scoped_affiliations } }
      let(:ids) { }
      let(:entity_id) { }
      let(:scoped_affiliations) { }

      it { is_expected.to eq [] }

      context 'institution_affiliations' do
        let(:institution_1) { create(:institution, identifier: '1', entity_id: 'entity_1') }
        let(:institution_1_affiliation_1) { create(:institution_affiliation, institution: institution_1, dlps_institution_id: 1, affiliation: 'member') }
        let(:institution_1_affiliation_2) { create(:institution_affiliation, institution: institution_1, dlps_institution_id: 3, affiliation: 'alum') }
        let(:institution_2) { create(:institution, identifier: '2', entity_id: 'entity_2') }
        let(:institution_2_affiliation_1) { create(:institution_affiliation, institution: institution_2, dlps_institution_id: 2, affiliation: 'member') }

        before do
          institution_1_affiliation_1
          institution_1_affiliation_2
          institution_2_affiliation_1
        end

        context 'ip_based' do
          let(:ids) { [institution_2.identifier] }
          let(:entity_id) { 'entity_id' }

          it { is_expected.to contain_exactly(institution_2_affiliation_1) }
        end

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to contain_exactly(institution_1_affiliation_1) }

          context 'eduPersonScopedAffiliation' do
            let(:scoped_affiliations) { ['staff@x.y.z', 'alum@z.y.x', 'joker@z.z.z'] }

            it { is_expected.to contain_exactly(institution_1_affiliation_2) }
          end
        end

        context 'both' do
          let(:ids) { [institution_1.identifier, institution_2.identifier] }
          let(:entity_id) { institution_1.entity_id }

          it { is_expected.to contain_exactly(institution_1_affiliation_1, institution_2_affiliation_1) }

          context 'eduPersonScopedAffiliation' do
            let(:scoped_affiliations) { ['staff@x.y.z', 'alum@z.y.x', 'joker@z.z.z'] }

            it { is_expected.to contain_exactly(institution_1_affiliation_1, institution_1_affiliation_2, institution_2_affiliation_1) }
          end
        end
      end
    end
  end
end
