# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographIndexer do
  describe 'indexing a monograph' do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(monograph) }
    let(:press) { create(:press, parent: parent_press) }
    let(:monograph) {
      build(:monograph,
            title: ['"Blah"-de-blah-blah and Stuff!'],
            # throwing messy spaces in to test strip and rejection of blanks in ORCID processing
            creator: ["Moose, Bullwinkle\n"\
                      "|https://orcid.org/dont-index-me\n"\
                      "Squirrel, Rocky|https://orcid.org/0000-0002-1825-0097\n\n"\
                      "Badenov, Boris  \n"\
                      " Fatale, Natasha |  https://orcid.org/0000-0002-1825-0097 "],
            contributor: ["Moose, Bullwinkley\n"\
                          "|https://orcid.org/dont-index\n"\
                          "Squirrel, Rock|https://orcid.org/0000-0002-1825-0097\n\n"\
                          "Badenovy, Boris  \n"\
                          " Fataley, Natasha |  https://orcid.org/0000-0002-1825-0097 "],
            description: ["This is the abstract"],
            date_created: date_created,
            isbn: ['978-0-252012345 (paper)', '978-0252023456 (hardcover)', '978-1-62820-123-9 (e-book)'],
            identifier: ['bar_number:S0001', 'heb_id: heb9999.0001.001'],
            press: press.subdomain,
            doi: "10.3998/mpub.test")
    }
    let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    let(:press_name) { press.name }
    let(:parent_press) { nil }
    let(:date_created) { ['2018'] }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it 'indexes the ordered members' do
      expect(subject['ordered_member_ids_ssim']).to eq [file_set.id]
    end

    it "indexes it's DOI and also the full DOI 'url'" do
      expect(subject['doi_ssim']).to eq ["10.3998/mpub.test"]
      expect(subject['doi_url_ssim']).to eq "https://doi.org/10.3998/mpub.test"
    end

    describe 'press name' do
      context 'no parent press' do
        it 'does not index a facetable value' do
          expect(subject['press_name_ssim']).to eq press_name # symbol
          expect(subject['press_name_sim']).to eq nil # facetable
        end
      end

      context 'parent press subdomain is not "michigan" or "mps"' do
        let(:parent_press) { create(:press, subdomain: 'blah') }

        it 'does not index a facetable value' do
          expect(subject['press_name_ssim']).to eq press_name # symbol
          expect(subject['press_name_sim']).to eq nil # facetable
        end
      end

      context 'parent press subdomain is "michigan"' do
        let(:parent_press) { create(:press, subdomain: 'michigan') }

        it 'indexes a facetable value' do
          expect(subject['press_name_ssim']).to eq press_name # symbol
          expect(subject['press_name_sim']).to eq press_name # facetable
        end
      end

      context 'parent press subdomain is "mps"' do
        let(:parent_press) { create(:press, subdomain: 'mps') }

        it 'indexes a facetable value' do
          expect(subject['press_name_ssim']).to eq press_name # symbol
          expect(subject['press_name_sim']).to eq press_name # facetable
        end
      end
    end

    context "ebook metadata indexed at the Monograph level" do
      before do
        create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: "epub")
        UnpackJob.perform_now(file_set.id, "epub") # to index the epub's table of contents HELIO-3870 and a11y metadata HELIO-4125
      end

      context 'ebook representative table of contents' do
        it "indexes the epub/pdf_ebook's ToC if there is one" do
          expect(subject['table_of_contents_tesim']).to include("Chapter 73. Stubb and Flask Kill a Right Whale; and Then Have a Talk")
        end
      end

      context 'Accessibility metadata' do
        context 'EPUB' do
          context 'Runs EpubAccessibilityMetadataIndexingService' do
            it 'indexes fields from the EPUB OPF "package" file on the Monograph' do
              # checking that `version` was indexed wll suffice, EpubAccessibilityMetadataIndexingServiceSpec covers them all
              expect(subject['epub_version_ssi']).to eq("3.0")
            end
          end
        end

        context 'pdf_ebook' do
          let(:pdf_file_set) { create(:file_set) }
          before do
            create(:featured_representative, work_id: monograph.id, file_set_id: pdf_file_set.id, kind: "pdf_ebook")
          end

          context 'indexes "unknown" for "Sceen reader friendly"' do
            it 'indexes fields from the EPUB OPF "package" file on the Monograph' do
              # checking that `version` was indexed wll suffice, EpubAccessibilityMetadataIndexingServiceSpec covers them all
              expect(subject['epub_a11y_screen_reader_friendly_ssi']).to eq('unknown')
            end
          end
        end
      end
    end

    it 'indexes the representative_id' do
      expect(subject['representative_id_ssim']).to eq monograph.representative_id
    end

    it 'has a single-valued, downcased-and-cleaned-up title to sort by' do
      expect(subject['title_si']).to eq 'blah-de-blah-blah and stuff'
    end

    it "indexes all creators' names for access/search and faceting" do
      expect(subject['creator_tesim']).to eq ['Moose, Bullwinkle', 'Squirrel, Rocky', 'Badenov, Boris', 'Fatale, Natasha'] # access/search
      expect(subject['creator_sim']).to eq ['Moose, Bullwinkle', 'Squirrel, Rocky', 'Badenov, Boris', 'Fatale, Natasha'] # facet
    end

    it "indexes first creator's name for access/search and (normalized) for sorting" do
      expect(subject['creator_full_name_tesim']).to eq 'Moose, Bullwinkle' # access/search
      expect(subject['creator_full_name_si']).to eq 'moose bullwinkle' # facet
    end

    it "indexes creator ORCIDs in a parallel array" do
      expect(subject['creator_orcids_ssim']).to eq ['', 'https://orcid.org/0000-0002-1825-0097', '', 'https://orcid.org/0000-0002-1825-0097']
    end

    it "indexes authorship fields in their backup/importable form for quick access, e.g. ScholarlyiQ export" do
      expect(subject['creator_ss'])
        .to eq "Moose, Bullwinkle; |https://orcid.org/dont-index-me; Squirrel, Rocky|https://orcid.org/0000-0002-1825-0097; Badenov, Boris; Fatale, Natasha |  https://orcid.org/0000-0002-1825-0097"
      expect(subject['contributor_ss'])
        .to eq "Moose, Bullwinkley; |https://orcid.org/dont-index; Squirrel, Rock|https://orcid.org/0000-0002-1825-0097; Badenovy, Boris; Fataley, Natasha |  https://orcid.org/0000-0002-1825-0097"
    end

    it 'has description indexed by Hyrax::IndexesBasicMetadata' do
      expect(subject['description_tesim'].first).to eq 'This is the abstract'
    end

    it 'indexes identifiers stored searchable (as they are) and also as symbols (trimmed and sans namespaces)' do
      expect(subject['identifier_tesim']).to contain_exactly('bar_number:S0001', 'heb_id:heb9999.0001.001')
      expect(subject['identifier_ssim']).to contain_exactly('S0001', 'heb9999.0001.001')
    end

    # 'isbn_numeric' is an isbn indexed multivalued field for finding books which is copied from 'isbn_tesim'
    #   <copyField source="isbn_tesim" dest="isbn_numeric"/>
    # the english text stored indexed multivalued field generated for the 'isbn' property a.k.a. object.isbn
    # See './app/models/monograph.rb' and './solr/config/schema.xml' for details.
    # Note: Since this happens server side see './solr/spec/core_spec.rb' for specs.

    context 'date_created' do
      it 'has a single-valued date_created value to sort by' do
        expect(subject['date_created_si']).to eq '2018'
      end

      context 'messy value' do
        let(:date_created) { ['c.2018?'] }

        it 'has a cleaned-up, single-valued (sortable) date_created value to sort by' do
          expect(subject['date_created_si']).to eq '2018'
        end
      end

      context 'extra-digits and separators' do
        let(:date_created) { ['2018/09/09'] }

        it 'has a cleaned-up, 4-digit, single-valued (sortable) date_created value to sort by' do
          expect(subject['date_created_si']).to eq '2018'
        end
      end
    end

    context 'products' do
      let(:products) { [-1, 0, 1] }
      let(:product) { instance_double(Greensub::Product, 'product', name: 'Product') }

      before do
        allow(indexer).to receive(:all_product_ids_for_monograph).with(monograph).and_return(products)
        allow(Greensub::Product).to receive(:where).with(id: products).and_return([product])
      end

      it { expect(subject['products_lsim']).to be(products) }
      it { expect(subject['product_names_sim']).to contain_exactly('Open Access', 'Unrestricted', 'Product') }
    end
  end

  describe 'empty creator field' do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(monograph) }
    let(:monograph) {
      build(:monograph,
            contributor: ["Moose, Bullwinkle\nSquirrel, Rocky"])
    }

    before do
      monograph.save!
    end

    it 'promotes the first contributor to creator' do
      expect(subject['creator_tesim']).to eq ['Moose, Bullwinkle']
      expect(subject['contributor_tesim']).to eq ['Squirrel, Rocky']
    end
  end

  describe '#all_product_ids_for_monograph' do
    subject { indexer.all_product_ids_for_monograph(monograph) }

    let(:indexer) { described_class.new(monograph) }
    let(:monograph) { create(:monograph) }

    it { is_expected.to contain_exactly(0) }

    context 'open access' do
      before { allow(monograph).to receive(:open_access).and_return('yes') }

      it { is_expected.to contain_exactly(-1, 0) }
    end

    context 'component' do
      let(:component) { instance_double(Greensub::Component, 'component', products: products) }
      let(:products) { [] }

      before do
        allow(Greensub::Component).to receive(:find_by).with(noid: monograph.id).and_return(component)
      end

      # Components without Products shouldn't exist really, but it's possible to have them
      # to we need to account for them.
      # A Component without a Product is not "nothing" or empty or [], which would leave it without
      # an Access Icon. Instead it's considered "0" or Unregistered.

      it { is_expected.to eq [0] }

      context 'open access' do
        before { allow(monograph).to receive(:open_access).and_return('yes') }

        # A component, with NO product, but that's still open access? I mean, I guess
        # it's both Open Access AND Unregistered. It's the same as below, where the
        # component DOES have a Product but is ALSO Open Access.

        it { is_expected.to contain_exactly(-1, 0) }
      end

      context 'product' do
        let(:products) { [product] }
        let(:product) { instance_double(Greensub::Product, 'product', id: 1) }

        it { is_expected.to contain_exactly(product.id) }

        context 'open access' do
          before { allow(monograph).to receive(:open_access).and_return('yes') }

          # The Component is both Open Access and belongs to a Product

          it { is_expected.to contain_exactly(-1, product.id) }
        end
      end

      context 'products' do
        let(:products) { [product1, product2] }
        let(:product1) { instance_double(Greensub::Product, 'product1', id: 1) }
        let(:product2) { instance_double(Greensub::Product, 'product2', id: 2) }

        it { is_expected.to contain_exactly(product1.id, product2.id) }

        context 'open access' do
          before { allow(monograph).to receive(:open_access).and_return('yes') }

          it { is_expected.to contain_exactly(-1, product1.id, product2.id) }
        end
      end
    end
  end

  describe "#table_of_contents" do
    context "no epub or pdf_ebook" do
      it "returns an empty list" do
        expect(described_class.new(Monograph.new).table_of_contents('somenoid')).to eq []
      end
    end

    context "an epub with no toc" do
      let(:rep) { create(:featured_representative, kind: 'epub') }

      it "returns an empty list" do
        expect(described_class.new(Monograph.new).table_of_contents(rep.work_id)).to eq []
      end
    end

    context "a pdf_ebook (no available epub) with no toc" do
      let(:rep) { create(:featured_representative, kind: 'pdf_ebook') }

      it "returns an empty list" do
        expect(described_class.new(Monograph.new).table_of_contents(rep.work_id)).to eq []
      end
    end

    context "an epub with a toc" do
      let(:toc) {
        [
          { title: "Front Cover", level: 1, cfi: "/OEBPS/Cover.xhtml" },
          { title: "Chapter 1: The Starting", level: 1, cfi:  "/OEBPS/1.xhtml" },
          { title: "Chapter 2: The Ending", level: 1, cfi: "/OEBPS/2.xhtml" }
        ]
      }
      let(:rep) { create(:featured_representative, kind: 'epub') }

      before do
        EbookTableOfContentsCache.create(noid: rep.file_set_id, toc: toc.to_json)
      end

      it "returns the table of contents titles" do
        expect(described_class.new(Monograph.new).table_of_contents(rep.work_id)).to eq ["Front Cover", "Chapter 1: The Starting", "Chapter 2: The Ending"]
      end
    end

    context "an epub and a pdf_ebook with tocs" do
      let(:monograph_noid) { "aa1234kl0" }
      let(:epub_toc) {
        [
          { title: "epub toc", level: 1, cfi: "/OEBPS/Cover.xhtml" }
        ]
      }
      let(:pdf_toc) {
        [
          { title: "pdf toc", level: 1, cfi: "page=1" }
        ]
      }
      let(:pdf) { create(:featured_representative, work_id: monograph_noid, kind: 'pdf_ebook') }
      let(:epub) { create(:featured_representative, work_id: monograph_noid, kind: 'epub') }

      before do
        EbookTableOfContentsCache.create(noid: pdf.file_set_id, toc: pdf_toc.to_json)
        EbookTableOfContentsCache.create(noid: epub.file_set_id, toc: epub_toc.to_json)
      end

      it "returns the epub table of contents titles" do
        expect(described_class.new(Monograph.new).table_of_contents(monograph_noid)).to eq ["epub toc"]
      end
    end

    describe 'date_published field' do
      subject { indexer.generate_solr_document }

      let(:indexer) { described_class.new(monograph) }
      let(:monograph) { create(:monograph, date_published: date_published, visibility: visibility) }

      context 'date_published has been explicitly set' do
        let(:date_published) { [Hyrax::TimeService.time_in_utc] }

        context 'draft Monograph' do
          let(:visibility) { 'restricted' }

          it 'indexes the first value of date_published (a multi-valued field we use as single-valued)' do
            expect(subject['date_published_si']).to eq date_published.first.to_i
            # refresher: cause `.utc.iso8601` is how values detected as dates are indexed in ActiveFedora
            # https://github.com/samvera/active_fedora/blob/8e7d365a087974b4ff9b9217f792c0c049789de6/lib/active_fedora/indexing/default_descriptors.rb#L114
            expect(subject['date_published_dtsim']).to eq [date_published.first.utc.iso8601]
          end
        end

        context 'public Monograph' do
          let(:visibility) { 'open' }

          it 'indexes the first value of date_published (a multi-valued field we use as single-valued)' do
            expect(subject['date_published_si']).to eq date_published.first.to_i
            # refresher: cause `.utc.iso8601` is how values detected as dates are indexed in ActiveFedora
            # https://github.com/samvera/active_fedora/blob/8e7d365a087974b4ff9b9217f792c0c049789de6/lib/active_fedora/indexing/default_descriptors.rb#L114
            expect(subject['date_published_dtsim']).to eq [date_published.first.utc.iso8601]
          end
        end
      end

      context 'date_published has not been explicitly set' do
        let(:date_published) { nil }

        context 'draft Monograph' do
          let(:visibility) { 'restricted' }

          it "does nothing with date_published" do
            expect(subject['date_published_si']).to eq nil
            expect(subject['date_published_dtsim']).to eq nil
          end
        end

        context 'public Monograph' do
          let(:visibility) { 'open' }

          it "monograph's date_published gets set automatically on creation, and is used for indexing" do
            expect(subject['date_published_si']).to eq monograph.date_published.first.to_i
            # refresher: cause `.utc.iso8601` is how values detected as dates are indexed in ActiveFedora
            # https://github.com/samvera/active_fedora/blob/8e7d365a087974b4ff9b9217f792c0c049789de6/lib/active_fedora/indexing/default_descriptors.rb#L114
            expect(subject['date_published_dtsim']).to eq [monograph.date_published.first.utc.iso8601]
          end
        end
      end
    end
  end
end
