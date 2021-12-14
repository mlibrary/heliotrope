# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Monograph, type: :model do
  describe 'monograph with resources' do
    subject { Sighrax.from_noid(monograph.id) }

    let(:press) { create(:press, subdomain: 'subdomain') }
    let(:monograph) do
      create(:public_monograph,
             buy_url: ['buy_url'],
             contributor: ['contributor'],
             creator: ['creator'],
             date_created: ['c1999e'],
             date_modified: date_modified,
             date_published: [date_published],
             description: ['description'],
             language: ['language'],
             press: 'subdomain',
             publisher: ['publishing house'],
             representative_id: cover.id,
             series: ['series'],
             subject: ['subject'])
    end
    let(:date_modified) { Time.utc(2000, 2, 2) }
    let(:date_published) { Time.utc(2001, 11, 11) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set) }
    let(:pdf_ebook) { create(:public_file_set) }
    let(:file_set) { create(:public_file_set) }
    let(:epub_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:pdf_ebook_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf_ebook.id, kind: 'pdf_ebook') }

    before do
      press
      monograph.ordered_members = [cover, epub, pdf_ebook, file_set]
      monograph.save
      cover.save
      epub.save
      pdf_ebook.save
      file_set.save
      epub_fr
      pdf_ebook_fr
    end

    it 'has expected values' do
      is_expected.to be_an_instance_of described_class
      is_expected.to be_a_kind_of Sighrax::Work
      expect(subject.resource_type).to eq :Monograph

      expect(subject.buy_url).to eq 'buy_url'
      expect(subject.contributors).to contain_exactly('creator', 'contributor')
      expect(subject.cover.noid).to eq cover.id
      expect(subject.description).to eq 'description'
      expect(subject.ebook.noid).to eq epub.id
      expect(subject.epub_ebook.noid).to eq epub.id
      expect(subject.identifier).to eq HandleNet.url(monograph.id)
      expect(subject.languages).to contain_exactly('language')
      expect(subject.modified).to eq date_modified
      expect(subject.open_access?).to be false
      expect(subject.pdf_ebook.noid).to eq pdf_ebook.id
      expect(subject.products).to be_empty
      expect(subject.publication_year).to eq '1999'
      expect(subject.published).to eq date_published
      expect(subject.publisher).to eq Sighrax::Publisher.from_press(press)
      expect(subject.publishing_house).to eq 'publishing house'
      expect(subject.restricted?).to be false
      expect(subject.series).to eq 'series'
      expect(subject.subjects).to contain_exactly('subject')

      expect(subject.parent).to be_an_instance_of Sighrax::NullEntity
      expect(subject.children).to contain_exactly(
        Sighrax.from_noid(cover.id),
        Sighrax.from_noid(epub.id),
        Sighrax.from_noid(pdf_ebook.id),
        Sighrax.from_noid(file_set.id)
      )
    end
  end

  describe '#identifier' do
    subject { Sighrax.from_noid(monograph.id).identifier }

    let(:monograph) { create(:public_monograph) }

    it { is_expected.to eq HandleNet.url(monograph.id) }

    context 'handle' do
      before do
        monograph.hdl = 'hdl'
        monograph.save
      end

      it { is_expected.to eq HandleNet::HANDLE_NET_PREFIX + 'hdl' }

      context 'doi' do
        before do
          monograph.doi = 'doi'
          monograph.save
        end

        it { is_expected.to eq HandleNet::DOI_ORG_PREFIX + 'doi' }
      end
    end
  end

  describe '#modified' do
    subject { Sighrax.from_noid(monograph.id).modified }

    let(:monograph) { create(:public_monograph) }
    let(:yesterday) { 1.day.ago.utc }

    before do
      monograph.date_modified = yesterday
      monograph.save
    end

    it { is_expected.to eq Time.parse(yesterday.iso8601) } # Truncate to second }

    it 'Aptrust Deposit updated_at' do
      record = AptrustDeposit.create(noid: monograph.id, identifier: monograph.id, verified: true)
      is_expected.to eq record.updated_at
      is_expected.not_to eq yesterday
    end
  end

  describe '#open_access?, #products, and #unrestricted?' do
    subject { Sighrax.from_noid(monograph.id) }

    let(:monograph) { create(:public_monograph) }

    it do
      expect(subject.restricted?).to be false
      expect(subject.open_access?).to be false
    end

    context 'when component' do
      let(:component) { create(:component, identifier: monograph.id, noid: monograph.id) }

      it 'has expected values' do
        expect(subject.products).to be_empty
        expect(subject.restricted?).to be false
        expect(subject.open_access?).to be false
      end

      context 'when component of product' do
        let(:product) { create(:product) }

        before do
          component.products << product
          component.save
        end

        it 'has expected values' do
          expect(subject.products).not_to be_empty
          expect(subject.products).to eq(Greensub::Product.containing_monograph(monograph.id))
          expect(subject.restricted?).to be true
          expect(subject.open_access?).to be false
        end

        context 'when open access' do
          before do
            monograph.open_access = 'yes'
            monograph.save
          end

          it 'has expected values' do
            expect(subject.products).not_to be_empty
            expect(subject.products).to eq(Greensub::Product.containing_monograph(monograph.id))
            expect(subject.restricted?).to be true
            expect(subject.open_access?).to be true
          end
        end
      end
    end
  end

  describe '#worldcat_url' do
    subject { Sighrax.from_noid(monograph.id).worldcat_url }

    context 'monograph without isbns' do
      let(:monograph) { create(:public_monograph) }

      it { is_expected.to be_empty }
    end

    context 'isbns' do
      let(:monograph) { create(:public_monograph, isbn: isbns) }
      let(:isbns) { [] }

      it { is_expected.to be_empty }

      context 'blank' do
        let(:isbns) { [''] }

        it { is_expected.to be_empty }
      end

      context 'alphabetic garbage' do
        let(:isbns) { ['a string with no numbers (unknown) trailer junk'] }

        it { is_expected.to be_empty }
      end

      context 'alphanumeric garbage' do
        let(:isbns) { ['a 1 string 2 with 3 numbers 4 (unknown) 5 trailer 6 junk'] }

        it { is_expected.to eq 'http://www.worldcat.org/isbn/4' }
      end

      context 'isbn precedence' do
        let(:none) { '00-00-00-00-00' }
        let(:unknown) { '111-111-111-1 (unknown)' }
        let(:ebook) { '2222-2222-22 (ebook)' }
        let(:hardcover) { '3-33-333-3333 (hardcover)' }
        let(:paper) { '444-44-4-4444 (paper)' }

        let(:isbns) { [unknown, hardcover, none, ebook, paper] }

        it { is_expected.to eq 'http://www.worldcat.org/isbn/2222222222' }

        context 'no ebook' do
          let(:isbns) { [unknown, hardcover, none, paper] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3333333333' }

          context 'no hardcover' do
            let(:isbns) { [unknown, none, paper] }

            it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444444' }

            context 'no paper' do
              let(:isbns) { [unknown, none] }

              it { is_expected.to eq 'http://www.worldcat.org/isbn/0000000000' }

              context 'unknown' do
                let(:isbns) { [unknown] }

                it { is_expected.to eq 'http://www.worldcat.org/isbn/1111111111' }
              end
            end
          end
        end
      end
    end
  end
end
