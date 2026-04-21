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
      expect(subject.identifier).to eq HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + monograph.id
      expect(subject.languages).to contain_exactly('language')

      # Here we'll show the model is aliasing the Hyrax (date_modified) to Fedora (modified_date). The latter is...
      # indexed here with the name `system_modified`
      # see here:
      # https://github.com/samvera/active_fedora/blob/87e1f5b0c9f5bc5be1ccdc8ff1d25cbd5661c7a9/lib/active_fedora/indexing_service.rb#L56
      # and here:
      # https://github.com/samvera/active_fedora/blob/87e1f5b0c9f5bc5be1ccdc8ff1d25cbd5661c7a9/lib/active_fedora/indexing_service.rb#L36
      doc = ActiveFedora::SolrService.query("{!terms f=id}#{monograph.id}", rows: 1).first
      expect(doc['date_modified_dtsi']).to eq(doc['system_modified_dtsi'])

      # see `modified()` in Sighrax::Model, again, remember `date_modified` and `modified_date` are aliased, and that
      # `modified_date` is indexed as `system_modified_dtsi`
      expect(subject.modified).to eq Time.parse(doc['system_modified_dtsi']).utc

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

    it { is_expected.to eq HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + monograph.id }

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

    it 'reports modified_date as this field is indexed as `date_modified_dtsi` due to aliasing in the Monograph model' do
      is_expected.to eq Time.parse(monograph.modified_date.iso8601) # Truncate to second }
    end

    it 'Aptrust Deposit updated_at' do
      record = AptrustDeposit.create(noid: monograph.id, identifier: monograph.id, verified: true)
      is_expected.to eq record.updated_at
      is_expected.not_to eq yesterday
    end
  end

  describe '#open_access?, #products, #product_ids, and #unrestricted?' do
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
        expect(subject.product_ids).to eq [0] # 0 is the default fake No Product product
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
          expect(subject.product_ids).to eq [product.id]
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
            expect(subject.product_ids).to eq [-1, product.id]  # -1 is the Open Access fake product
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

      context 'ISBN-10 with X check digit (no type)' do
        let(:isbns) { ['019853453X'] }

        it { is_expected.to eq 'http://www.worldcat.org/isbn/019853453X' }
      end

      context 'ISBN-10 with X check digit and type' do
        let(:isbns) { ['019853453X (hardcover)'] }

        it { is_expected.to eq 'http://www.worldcat.org/isbn/019853453X' }
      end

      # This logic also exists in app/jobs/build_kbart_job.rb, which is what it is.
      # I think we're getting settled into what we consider to be "the" ISBN of a book,
      # and soon we might want to consolidate the code in a central place.
      context 'isbn precedence' do
        let(:none) { '00-00-00-00-00' }
        let(:unknown) { '111-111-111-1 (unknown)' }
        let(:open_access) { '1234-5678-90 (open access)' }
        let(:ebook) { '2222-2222-22 (ebook)' }
        let(:pdf) { '2345-6789-01 (PDF)' }
        let(:hardcover) { '3-33-333-3333 (hardcover)' }
        let(:paper) { '444-44-4-4444 (paper)' }
        let(:paper_with_cd) { '5555-5555-55 (paper with cd)' }

        context 'with open access (highest priority)' do
          let(:isbns) { [unknown, paper_with_cd, paper, hardcover, pdf, ebook, open_access, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/1234567890' }
        end

        context 'with open-access variant' do
          let(:open_access_variant) { '1234-5678-91 (open-access)' }
          let(:isbns) { [unknown, paper, hardcover, ebook, open_access_variant, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/1234567891' }
        end

        context 'with OA variant' do
          let(:oa) { '1234-5678-92 (OA)' }
          let(:isbns) { [unknown, paper, hardcover, ebook, oa, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/1234567892' }
        end

        context 'no open access, with ebook' do
          let(:isbns) { [unknown, paper_with_cd, paper, hardcover, pdf, ebook, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/2222222222' }
        end

        context 'with e-book variant' do
          let(:ebook_variant) { '2222-2222-23 (e-book)' }
          let(:isbns) { [unknown, paper, hardcover, ebook_variant, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/2222222223' }
        end

        context 'with ebook epub variant' do
          let(:ebook_epub) { '2222-2222-24 (ebook epub)' }
          let(:isbns) { [unknown, paper, hardcover, ebook_epub, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/2222222224' }
        end

        context 'no ebook, with PDF' do
          let(:isbns) { [unknown, paper_with_cd, paper, hardcover, pdf, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/2345678901' }
        end

        context 'with ebook pdf variant' do
          let(:ebook_pdf) { '2345-6789-02 (ebook pdf)' }
          let(:isbns) { [unknown, paper, hardcover, ebook_pdf, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/2345678902' }
        end

        context 'no pdf, with hardcover' do
          let(:isbns) { [unknown, paper_with_cd, paper, hardcover, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3333333333' }
        end

        context 'with cloth variant' do
          let(:cloth) { '3333-3333-34 (cloth)' }
          let(:isbns) { [unknown, paper, cloth, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3333333334' }
        end

        context 'with Hardcover (capitalized) variant' do
          let(:hardcover_cap) { '3333-3333-35 (Hardcover)' }
          let(:isbns) { [unknown, paper, hardcover_cap, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3333333335' }
        end

        context 'no hardcover, with print' do
          let(:print) { '3456-7890-12 (print)' }
          let(:isbns) { [unknown, paper_with_cd, paper, print, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3456789012' }
        end

        context 'with hardcover : alk. paper variant' do
          let(:hc_alk) { '3456-7890-13 (hardcover : alk. paper)' }
          let(:isbns) { [unknown, paper, hc_alk, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3456789013' }
        end

        context 'with hc. : alk. paper variant' do
          let(:hc_alk_short) { '3456-7890-14 (hc. : alk. paper)' }
          let(:isbns) { [unknown, paper, hc_alk_short, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/3456789014' }
        end

        context 'no print, with paper' do
          let(:isbns) { [unknown, paper_with_cd, paper, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444444' }
        end

        context 'with paperback variant' do
          let(:paperback) { '4444-4444-45 (paperback)' }
          let(:isbns) { [unknown, paperback, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444445' }
        end

        context 'with Paper (capitalized) variant' do
          let(:paper_cap) { '4444-4444-46 (Paper)' }
          let(:isbns) { [unknown, paper_cap, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444446' }
        end

        context 'with pb. variant' do
          let(:pb) { '4444-4444-47 (pb.)' }
          let(:isbns) { [unknown, pb, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444447' }
        end

        context 'with pb. : alk. paper variant' do
          let(:pb_alk) { '4444-4444-48 (pb. : alk. paper)' }
          let(:isbns) { [unknown, pb_alk, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/4444444448' }
        end

        context 'no paper, with paper with cd' do
          let(:isbns) { [unknown, paper_with_cd, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/5555555555' }
        end

        context 'with paper plus cd rom variant' do
          let(:paper_cd_rom) { '5555-5555-56 (paper plus cd rom)' }
          let(:isbns) { [unknown, paper_cd_rom, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/5555555556' }
        end

        context 'no paper with cd, with none' do
          let(:isbns) { [unknown, none] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/0000000000' }
        end

        context 'only unknown (fallback)' do
          let(:isbns) { [unknown] }

          it { is_expected.to eq 'http://www.worldcat.org/isbn/1111111111' }
        end
      end
    end
  end
end
