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
        # institutions auto-create one InstitutionAffiliation per AFFILIATION (member/alum/walk-in)
        # with dlps_institution_id equal to the institution's own identifier
        let(:institution_1) { create(:institution, identifier: '1', entity_id: 'entity_1') }
        let(:institution_2) { create(:institution, identifier: '2', entity_id: 'entity_2') }

        before do
          institution_1
          institution_2
        end

        context 'ip_based' do
          let(:ids) { [institution_2.identifier] }
          let(:entity_id) { 'entity_id' }

          # ip_based lookup by dlps_institution_id matches all auto-created affiliations for institution_2
          it { is_expected.to contain_exactly(*institution_2.institution_affiliations.to_a) }
        end

        context 'shib' do
          let(:ids) { ['ids'] }
          let(:entity_id) { institution_1.entity_id }

          # shib with default 'member' affiliation finds institution_1's auto-created member affiliation
          it { is_expected.to contain_exactly(*institution_1.institution_affiliations.where(affiliation: 'member').to_a) }

          context 'eduPersonScopedAffiliation' do
            let(:scoped_affiliations) { ['staff@x.y.z', 'alum@z.y.x', 'joker@z.z.z'] }

            # scoped affiliations map to 'alum' - finds institution_1's auto-created alum affiliation
            it { is_expected.to contain_exactly(*institution_1.institution_affiliations.where(affiliation: %w[staff alum joker]).to_a) }
          end
        end

        context 'both' do
          let(:ids) { [institution_1.identifier, institution_2.identifier] }
          let(:entity_id) { institution_1.entity_id }

          # ip_based finds all auto-created affiliations for both institutions;
          # shib adds institution_1 'member' (already present); combined result is all 6
          it { is_expected.to contain_exactly(*(institution_1.institution_affiliations.to_a + institution_2.institution_affiliations.to_a)) }

          context 'eduPersonScopedAffiliation' do
            let(:scoped_affiliations) { ['staff@x.y.z', 'alum@z.y.x', 'joker@z.z.z'] }

            # shib adds institution_1 'alum' (already in ip_based results); combined still all 6
            it { is_expected.to contain_exactly(*(institution_1.institution_affiliations.to_a + institution_2.institution_affiliations.to_a)) }
          end
        end
      end
    end
  end
end
