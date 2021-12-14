# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Institution, type: :model do
  context 'instance' do
    subject { described_class.new(id: id, identifier: identifier, name: name, display_name: display_name, entity_id: entity_id, in_common: in_common) }

    let(:id) { 1 }
    let(:identifier) { 'identifier' }
    let(:name) { 'name' }
    let(:display_name) { 'display_name' }
    let(:entity_id) { 'entity_id' }
    let(:in_common) { true }

    it { is_expected.to be_a Greensub::Licensee }
    it { expect(subject.agent_type).to eq :Institution }
    it { expect(subject.agent_id).to eq id }

    describe '#shibboleth?' do
      it { expect(subject.shibboleth?).to be true }

      context 'not in common' do
        let(:in_common) { false }

        it { expect(subject.shibboleth?).to be false }
      end

      context 'entity id nil' do
        let(:entity_id) { nil }

        it { expect(subject.shibboleth?).to be false }
      end

      context 'entity id blank' do
        let(:entity_id) { '' }

        it { expect(subject.shibboleth?).to be false }
      end
    end
  end

  context 'validation' do
    subject { institution }

    let(:institution) { described_class.create!(params) }
    let(:params) { { identifier: identifier,
                     name: name,
                     display_name: display_name,
                     entity_id: entity_id,
                     catalog_url: catalog_url,
                     link_resolver_url: link_resolver_url,
                     location: location,
                     login: login,
                     logo_path: logo_path,
                     ror_id: ror_id,
                     site: site } }
    let(:identifier) { nil }
    let(:name) { nil }
    let(:display_name) { nil }
    let(:entity_id) { nil }
    let(:catalog_url) { nil }
    let(:link_resolver_url) { nil }
    let(:location) { nil }
    let(:login) { nil }
    let(:logo_path) { nil }
    let(:ror_id) { nil }
    let(:site) { nil }

    it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Identifier can't be blank, Identifier is not a number, Name can't be blank, Display name can't be blank") }
  end

  context 'before validation' do
    it 'on update' do
      institution = create(:institution)
      institution.identifier = 'new_identifier'
      expect(institution.save).to be false
      expect(institution.errors.count).to eq 1
      expect(institution.errors.first[0]).to eq :identifier
      expect(institution.errors.first[1]).to eq "institution identifier can not be changed!"
    end
  end

  context 'before destroy' do
    let(:institution) { create(:institution) }
    let(:product) { create(:product) }
    let(:license) { create(:full_license, licensee: institution, product: product) }

    it 'license present' do
      license
      expect(institution.destroy).to be false
      expect(institution.errors.count).to eq 1
      expect(institution.errors.first[0]).to eq :base
      expect(institution.errors.first[1]).to eq "Cannot delete record because dependent licenses exist"
    end
  end

  context 'methods' do
    subject { institution }

    let(:institution) { create(:institution) }

    before { clear_grants_table }

    it do
      is_expected.to be_valid
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    it 'grants' do
      product = create(:product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false

      subject.create_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be false
      expect(subject.grants?).to be true

      subject.delete_product_license(product)

      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.grants?).to be false
    end

    context 'products and components' do
      subject { create(:institution) }

      let(:product_1) { create(:product, identifier: 'product_1') }
      let(:component_a) { create(:component, identifier: 'component_a') }
      let(:product_2) { create(:product, identifier: 'product_2') }
      let(:component_b) { create(:component, identifier: 'component_b') }

      it do
        expect(subject.products.count).to be_zero

        product_1.components << component_a
        expect(subject.products.count).to eq 0

        product_2

        subject.create_product_license(product_2)
        expect(subject.products.count).to eq 1

        product_2.components << component_b
        expect(subject.products.count).to eq 1

        subject.create_product_license(product_1)
        expect(subject.products.count).to eq 2

        product_1.components << component_b
        expect(subject.products.count).to eq 2
      end
    end
  end

  describe 'institution affiliations' do
    let(:institutions) { [] }

    before do
      for i in 0..2
        institutions << create(:institution)
        for j in 0..Greensub::InstitutionAffiliation.affiliations.count - 1
          create(:institution_affiliation, institution: institutions[i], dlps_institution_id: 1 + (i * 100) + j, affiliation: Greensub::InstitutionAffiliation.affiliations[j])
        end
      end
    end

    it do
      expect(institutions[0].institution_affiliations.count).to eq Greensub::InstitutionAffiliation.affiliations.count
      expect(described_class.containing_dlps_institution_id(1).count).to eq 1
      expect(described_class.containing_dlps_institution_id(1).first).to eq institutions[0]
      expect(described_class.containing_dlps_institution_id(101).count).to eq 1
      expect(described_class.containing_dlps_institution_id(101).first).to eq institutions[1]
      expect(described_class.containing_dlps_institution_id(201).count).to eq 1
      expect(described_class.containing_dlps_institution_id(201).first).to eq institutions[2]
      expect(described_class.containing_dlps_institution_id([1, 2, 3]).count).to eq 1
      expect(described_class.containing_dlps_institution_id([1, 101, 201]).count).to eq 3
      expect(institutions[0].dlps_institution_ids).to contain_exactly(1, 2, 3)
      expect(institutions[1].dlps_institution_ids).to contain_exactly(101, 102, 103)
      expect(institutions[2].dlps_institution_ids).to contain_exactly(201, 202, 203)
    end
  end
end
