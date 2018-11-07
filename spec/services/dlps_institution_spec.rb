# frozen_string_literal: true

require 'rails_helper'

describe DlpsInstitution do
  describe '#find' do
    subject { described_class.new.find(request_attributes) }

    let(:request_attributes) { {} }

    it { is_expected.to eq [] }

    context 'request_attributes' do
      let(:request_attributes) { { dlpsInstitutionId: ids, identity_provider: entity_id } }
      let(:ids) {}
      let(:entity_id) {}

      it { is_expected.to eq [] }

      context 'institutions' do
        let(:institution_1) { create(:institution, identifier: '1', entity_id: 'entity_1') }
        let(:institution_2) { create(:institution, identifier: '2', entity_id: 'entity_2') }

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
    end
  end
end
