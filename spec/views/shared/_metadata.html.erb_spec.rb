# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_metadata.html.erb' do
  context 'with no presenter' do
    it 'has no metadata' do
      render
      expect(rendered).not_to match('citation')
    end
  end

  context 'with a monograph presenter' do
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['Sun Moon Dog'],
                       creator_tesim: ['Doggie, Boutros-Boutros', 'Meow, Chairman'],
                       publisher_tesim: ['Seeing Eye Press'],
                       date_created_tesim: ['2001'])
    }

    it 'has the correct metadata' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render

      expect(rendered).to match 'Sun Moon Dog'
      expect(rendered).to match 'Doggie, Boutros-Boutros'
      expect(rendered).to match 'Meow, Chairman'
      expect(rendered).to match 'Seeing'
      expect(rendered).to match '2001'
    end
  end

  context 'when the monograph has no date_published' do
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['Sun Moon Dog'],
                       creator_full_name_tesim: ['Boutros-Boutros Doggie'],
                       publisher_tesim: ['Seeing Eye Press'])
    }

    it 'has no citation_publication_date' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).not_to match('citation_publication_date')
    end
  end

  context 'when the monograph title has HTML characters' do
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: [%q(Bob's Red "Appleish" Flavour Ketchup is > Heinz Ketchup)],
                       creator_full_name_tesim: ['Bob'],
                       publisher_tesim: ['Swedish Red Apple'])
    }

    it 'escapes the characters correctly for use in meta tag parameter values' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match('Bob&#39;s Red &quot;Appleish&quot; Flavour Ketchup is &gt; Heinz Ketchup')
    end
  end

  context 'when the monograph title has special characters' do
    # See #870
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: [%q(Bob's “Smart” Dog’s "Rött" Äpple)],
                       creator_full_name_tesim: ['Bob'],
                       publisher_tesim: ['Swedish Red Apple'])
    }

    it 'renders the characters correctly' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match('Bob&#39;s “Smart” Dog’s &quot;Rött&quot; Äpple')
    end
  end

  context 'when the monographs description has markdown' do
    # HELIO-3513
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: [%q(Bob's “Smart” Dog’s "Rött" Äpple)],
                       creator_full_name_tesim: ['Bob'],
                       publisher_tesim: ['Swedish Red Apple'],
                       description_tesim: ['A book about _Italics_ and *Bold* text. Great Read! 5 Stars.'])
    }

    it 'renders the description correctly' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match('A book about Italics and Bold text. Great Read! 5 Stars.')
    end
  end

  context 'when the monograph has creators and contributors' do
    # See 879
    let(:solr_document) {
      SolrDocument.new(id: '1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['More Things About Stuff'],
                       contributor_tesim: ['Overlooked, Sir Always'],
                       creator_tesim: ['Blug Shoeman', 'Melissa Allen'],
                       publisher_tesim: ['Marge INC.'])
    }

    it 'creators are cited but contributors are not' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match 'Blug Shoeman'
      expect(rendered).to match 'Melissa Allen'
      expect(rendered).not_to match 'Overlooked, Sir Always'
    end
  end

  context "a monograph with a thumbnail (representative file_set)" do
    let(:solr_document) do
      ::SolrDocument.new(id: 'mono',
                         title_tesim: ['A Title'],
                         has_model_ssim: ['Monograph'],
                         hasRelatedMediaFragment_ssim: ['999999999'])
    end

    it 'renders the thumbnail url' do
      @monograph_presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match '/image-service/999999999/full/225,/0/default.jpg'
    end
  end

  # HELIO-3951 show the citation_pdf_url if there's a pdf_ebook and the client has permission to download.
  # This is by request from Google Scholar who we'll make an Institution so they can download and index restricted pdfs.
  context "a monograph with a pdf_ebook" do
    let(:monograph) {
      SolrDocument.new(id: 'monograph1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['Sun Moon Dog'])
    }
    let(:file_set) {
      SolrDocument.new(id: 'file_set1',
                       has_model_ssim: ['FileSet'],
                       title_tesim: ['Bark Bark Boop'])
    }

    context "a client that has permission to download" do
      let(:ebook_download_presenter) { double("pdf_ebook", downloadable?: true, present?: true, pdf_ebook: Hyrax::FileSetPresenter.new(file_set, nil)) }

      it 'renders the pdf_ebook download url' do
        @monograph_presenter = Hyrax::MonographPresenter.new(monograph, nil)
        @ebook_download_presenter = ebook_download_presenter
        allow(controller).to receive(:controller_name).and_return("monograph_catalog")
        render
        # Disable citation_pdf_url meta tags, HELIO-4103
        expect(rendered).not_to match '\"citation_pdf_url\" content=\"http://test.host/ebooks/file_set1/download\"'
      end
    end

    context "a client that DOES NOT have permission to download" do
      let(:ebook_download_presenter) { double("pdf_ebook", downloadable?: false, present?: true, pdf_ebook: Hyrax::FileSetPresenter.new(file_set, nil)) }

      it 'does not render the pdf_ebook download url' do
        @monograph_presenter = Hyrax::MonographPresenter.new(monograph, nil)
        @ebook_download_presenter = ebook_download_presenter
        allow(controller).to receive(:controller_name).and_return("monograph_catalog")
        render

        expect(rendered).not_to match 'citation_pdf_url'
      end
    end
  end

  context 'with a file_set presenter' do
    let(:solr_document) {
      SolrDocument.new(id: '001',
                       has_model_ssim: ['FileSet'],
                       title_tesim: ['Bark Bark Boop'],
                       creator_tesim: ['Noodles, Mr. Ramen', 'Rice, Ms. Tasty'],
                       sort_date_tesim: ['2011-01-01'])
    }

    it 'has the correct metadata' do
      @presenter = Hyrax::FileSetPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("file_sets")
      render
      expect(rendered).to match 'Bark Bark Boop'
      expect(rendered).to match 'Noodles, Mr. Ramen'
      expect(rendered).to match 'Rice, Ms. Tasty'
      expect(rendered).to match '2011'
      expect(rendered).to match '2027/fulcrum.001'
    end
  end

  context 'when the file_set has a doi' do
    let(:solr_document) {
      SolrDocument.new(id: '001',
                       has_model_ssim: ['FileSet'],
                       title_tesim: ['Bark Bark Boop'],
                       creator_tesim: ['Mr. Noodles'],
                       sort_date_tesim: ['2011-01-01'],
                       doi_ssim: ['10.3998/fulcrum.001'])
    }

    it 'has the doi metadata (but not the doi url)' do
      @presenter = Hyrax::FileSetPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("file_sets")
      render
      expect(rendered).to match '10.3998/fulcrum.001'
      expect(rendered).not_to match HandleNet::DOI_ORG_PREFIX
    end
  end

  context 'an epub in the ereader' do
    let(:monograph) {
      SolrDocument.new(id: 'monograph1',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['Sun Moon Dog'],
                       doi_ssim: ['10.3998/fulcrum.001'])
    }
    let(:file_set) {
      SolrDocument.new(id: 'file_set1',
                       has_model_ssim: ['FileSet'],
                       title_tesim: ['Bark Bark Boop'],
                       monograph_id_ssim: ["monograph1"],
                       doi_ssim: ['10.3998/fulcrum.001.cmp.1']) # ebook file_sets won't have DOIs in prod, but added here for the test
    }

    it "shows ebook metadata (which is actually the monograph's metadata for the most part)" do
      @parent_presenter = Hyrax::MonographPresenter.new(monograph, nil)
      @presenter = Hyrax::FileSetPresenter.new(file_set, nil)
      allow(controller).to receive(:controller_name).and_return("e_pubs")
      render
      expect(rendered).to match '10.3998/fulcrum.001' # monograph doi, not file_set
      expect(rendered).to match 'Ebook of Sun Moon Dog' # monograph title with "Ebook of " added to differentiate from the monograph_catalog page
    end
  end
end
