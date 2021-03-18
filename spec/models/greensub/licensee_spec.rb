# frozen_string_literal: true

require 'rails_helper'

class TestLicensee
  include ActiveModel::Model
  include Greensub::Licensee

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def agent_type
    TestLicensee
  end

  def agent_id
    id
  end
end

RSpec.describe Greensub::Licensee do
  subject { licensee }

  let(:licensee) { TestLicensee.new(id) }
  let(:id) { 'id' }
  let(:product) { create(:product) }

  before { clear_grants_table }

  it { is_expected.to be_a described_class }

  it { expect(licensee.product_license?(product)).to be false }
  it { expect(licensee.product_license(product)).to be nil }
  it { expect(licensee.products?).to be false }
  it { expect(licensee.products).to be_empty }
  it { expect(licensee.licenses?).to be false }
  it { expect(licensee.licenses).to be_empty }
  it { expect(licensee.grants?).to be false }
  it { expect(licensee.grants).to be_empty }

  context 'product license' do
    let(:license) { Greensub::License.last }
    let(:grant) { grants_table_last }

    before { licensee.update_product_license(product) }

    it { expect(licensee.product_license?(product)).to be true }
    it { expect(licensee.product_license(product)).to eq license }
    it { expect(licensee.products?).to be true }
    it { expect(licensee.products).to contain_exactly(product) }
    it { expect(licensee.licenses?).to be true }
    it { expect(licensee.licenses).to contain_exactly(license) }
    it { expect(licensee.grants?).to be true }
    it { expect(licensee.grants).to contain_exactly(grant) }

    it 'update product license' do
      id = license.id
      expect(license.type).to eq 'Greensub::FullLicense'
      licensee.update_product_license(product, license_type: "Greensub::TrialLicense")
      license = licensee.product_license(product)
      expect(license.id).to eq id
      expect(license.type).to eq 'Greensub::TrialLicense'
    end

    context 'second product' do
      let(:second_product) { create(:product) }

      let(:second_license) { Greensub::License.last }
      let(:second_grant) { grants_table_last }

      before do
        license
        grant
        licensee.update_product_license(second_product)
      end

      it { expect(licensee.product_license?(second_product)).to be true }
      it { expect(licensee.product_license(second_product)).to eq second_license }
      it { expect(licensee.products?).to be true }
      it { expect(licensee.products).to contain_exactly(product, second_product) }
      it { expect(licensee.licenses?).to be true }
      it { expect(licensee.licenses).to contain_exactly(license, second_license) }
      it { expect(licensee.grants?).to be true }
      it { expect(licensee.grants).to contain_exactly(grant, second_grant) }

      context 'delete first product' do
        before { licensee.delete_product_license(product) }

        it { expect(licensee.product_license?(product)).to be false }
        it { expect(licensee.product_license(product)).to be nil }
        it { expect(licensee.products?).to be true }
        it { expect(licensee.products).to contain_exactly(second_product) }
        it { expect(licensee.licenses?).to be true }
        it { expect(licensee.licenses).to contain_exactly(second_license) }
        it { expect(licensee.grants?).to be true }
        it { expect(licensee.grants).to contain_exactly(second_grant) }
      end
    end
  end
end
