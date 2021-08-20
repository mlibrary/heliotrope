# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::Licensee do
  subject { licensee }

  let(:product) { create(:product) }
  let(:read) { Greensub::ReadLicense.to_s }
  let(:full) { Greensub::FullLicense.to_s }

  before { clear_grants_table }

  [:individual, :institution].each do |licensee_class|
    describe "#{licensee_class}" do
      let(:licensee) { create(licensee_class) }

      it 'is a licensee with no license' do
        is_expected.to be_a described_class
        expect(licensee.find_product_license(product)).to be nil
        expect(licensee.products?).to be false
        expect(licensee.products).to be_empty
        expect(licensee.licenses?).to be false
        expect(licensee.licenses).to be_empty
        expect(licensee.grants?).to be false
        expect(licensee.grants).to be_empty
      end

      context 'product license' do
        let(:license) { Greensub::License.last }
        let(:grant) { grants_table_last }

        it 'is a licensee with a single license' do
          expect(licensee.create_product_license(product)).to eq license
          expect(licensee.find_product_license(product)).to eq license
          expect(license.type).to eq full
          expect(licensee.products?).to be true
          expect(licensee.products).to contain_exactly(product)
          expect(licensee.licenses?).to be true
          expect(licensee.licenses).to contain_exactly(license)
          expect(licensee.grants?).to be true
          expect(licensee.grants).to contain_exactly(grant)

          id = license.id
          license = licensee.create_product_license(product, type: read)
          expect(license.id).to eq id
          expect(license.type).to eq read
          expect(licensee.products?).to be true
          expect(licensee.products).to contain_exactly(product)
          expect(licensee.licenses?).to be true
          expect(licensee.licenses).to contain_exactly(license)
          expect(licensee.grants?).to be true
          expect(licensee.grants).to contain_exactly(grant)
        end

        context 'second product' do
          let(:second_product) { create(:product) }
          let(:second_license) { Greensub::License.last }
          let(:second_grant) { grants_table_last }

          it 'is a licensee with two licenses' do
            expect(licensee.create_product_license(product)).to eq license
            grant
            expect(licensee.create_product_license(second_product)).to eq second_license
            second_grant
            expect(licensee.find_product_license(second_product)).to eq second_license
            expect(licensee.products?).to be true
            expect(licensee.products).to contain_exactly(product, second_product)
            expect(licensee.licenses?).to be true
            expect(licensee.licenses).to contain_exactly(license, second_license)
            expect(licensee.grants?).to be true
            expect(licensee.grants).to contain_exactly(grant, second_grant)
          end

          context 'delete first product license' do
            it 'is a licensee with a single license' do
              expect(licensee.create_product_license(product)).to eq license
              grant
              expect(licensee.create_product_license(second_product)).to eq second_license
              second_grant
              expect(licensee.delete_product_license(product)).to eq license
              expect(licensee.find_product_license(product)).to be nil
              expect(licensee.products?).to be true
              expect(licensee.products).to contain_exactly(second_product)
              expect(licensee.licenses?).to be true
              expect(licensee.licenses).to contain_exactly(second_license)
              expect(licensee.grants?).to be true
              expect(licensee.grants).to contain_exactly(second_grant)
            end
          end

          context 'delete second product license' do
            it 'is a licensee with a single license' do
              expect(licensee.create_product_license(product)).to eq license
              grant
              expect(licensee.create_product_license(second_product)).to eq second_license
              second_grant
              expect(licensee.delete_product_license(second_product)).to eq second_license
              expect(licensee.find_product_license(second_product)).to be nil
              expect(licensee.products?).to be true
              expect(licensee.products).to contain_exactly(product)
              expect(licensee.licenses?).to be true
              expect(licensee.licenses).to contain_exactly(license)
              expect(licensee.grants?).to be true
              expect(licensee.grants).to contain_exactly(grant)
            end
          end

          context 'delete both product license' do
            it 'is a licensee with a single license' do
              expect(licensee.create_product_license(product)).to eq license
              grant
              expect(licensee.create_product_license(second_product)).to eq second_license
              second_grant

              expect(licensee.delete_product_license(second_product)).to eq second_license
              expect(licensee.find_product_license(second_product)).to be nil
              expect(licensee.products?).to be true
              expect(licensee.products).to contain_exactly(product)
              expect(licensee.licenses?).to be true
              expect(licensee.licenses).to contain_exactly(license)
              expect(licensee.grants?).to be true
              expect(licensee.grants).to contain_exactly(grant)

              expect(licensee.delete_product_license(product)).to eq license
              expect(licensee.find_product_license(product)).to be nil
              expect(licensee.products?).to be false
              expect(licensee.products).to be_empty
              expect(licensee.licenses?).to be false
              expect(licensee.licenses).to be_empty
              expect(licensee.grants?).to be false
              expect(licensee.grants).to be_empty
            end
          end
        end
      end

      context 'product license affiliations' do
        let(:full_license) { Greensub::License.last }
        let(:read_license) { Greensub::License.last }
        let(:full_grant) { grants_table_last }
        let(:read_grant) { grants_table_last }

        it 'handles affiliations' do
          Greensub::LicenseAffiliation::AFFILIATIONS.each do |affiliation|
            expect(licensee.create_product_license(product, affiliation: affiliation, type: full)).to eq full_license
            expect(licensee.find_product_license(product, affiliation: affiliation)).to eq full_license
          end
          expect(licensee.products?).to be true
          expect(licensee.products).to contain_exactly(product)
          expect(licensee.licenses?).to be true
          expect(licensee.licenses).to contain_exactly(full_license)
          expect(licensee.grants?).to be true
          expect(licensee.grants).to contain_exactly(full_grant)

          Greensub::LicenseAffiliation::AFFILIATIONS.each_with_index do |affiliation, index|
            expect(licensee.create_product_license(product, affiliation: affiliation, type: read)).to eq read_license
            expect(licensee.find_product_license(product, affiliation: affiliation)).to eq read_license
            if index < Greensub::LicenseAffiliation::AFFILIATIONS.count - 1
              if licensee.is_a?(Greensub::Individual)
                expect(Greensub::License.count).to eq 1
                expect(grants_table_count).to eq 1
              else
                expect(Greensub::License.count).to eq 2
                expect(grants_table_count).to eq 2
              end
            else
              expect(Greensub::License.count).to eq 1
              expect(grants_table_count).to eq 1
            end
          end
          expect(licensee.products?).to be true
          expect(licensee.products).to contain_exactly(product)
          expect(licensee.licenses?).to be true
          expect(licensee.licenses).to contain_exactly(read_license)
          expect(licensee.grants?).to be true
          expect(licensee.grants).to contain_exactly(read_grant)

          if licensee.is_a?(Greensub::Individual)
            expect(full_license.id).to eq read_license.id
            expect(full_grant.id).to eq read_grant.id
          else
            expect(full_license.id).not_to eq read_license.id
            expect(full_grant.id).not_to eq read_grant.id
          end
        end
      end
    end
  end
end
