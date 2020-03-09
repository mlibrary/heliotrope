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
      @presenter = Hyrax::MonographPresenter.new(solr_document, nil)
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
      @presenter = Hyrax::MonographPresenter.new(solr_document, nil)
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
      @presenter = Hyrax::MonographPresenter.new(solr_document, nil)
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
      @presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match('Bob&#39;s “Smart” Dog’s &quot;Rött&quot; Äpple')
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
      @presenter = Hyrax::MonographPresenter.new(solr_document, nil)
      allow(controller).to receive(:controller_name).and_return("monograph_catalog")
      render
      expect(rendered).to match 'Blug Shoeman'
      expect(rendered).to match 'Melissa Allen'
      expect(rendered).not_to match 'Overlooked, Sir Always'
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
end
