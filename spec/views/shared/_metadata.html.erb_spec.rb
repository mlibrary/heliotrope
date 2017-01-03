require 'rails_helper'

describe 'shared/_metadata.html.erb' do
  context "with no presenter" do
    it "has no metadata" do
      render
      expect(rendered).not_to match('citation')
    end
  end

  context "with a monograph presenter" do
    let(:solr_document) { SolrDocument.new(id: '1',
                                           has_model_ssim: ['Monograph'],
                                           title_tesim: ['Sun Moon Dog'],
                                           creator_full_name_tesim: ['Boutros-Boutros Doggie'],
                                           press_name_ssim: ['Seeing Eye Press'],
                                           date_published_tesim: ['2001']) }
    it "has the correct metadata" do
      @monograph_presenter = CurationConcerns::MonographPresenter.new(solr_document, nil)
      render
      expect(rendered).to match('Sun Moon Dog')
      expect(rendered).to match('Boutros-Boutros')
      expect(rendered).to match('Seeing')
      expect(rendered).to match('2001')
    end
  end

  context "when the monograph has no date_published" do
    let(:solr_document) { SolrDocument.new(id: '1',
                                           has_model_ssim: ['Monograph'],
                                           title_tesim: ['Sun Moon Dog'],
                                           creator_full_name_tesim: ['Boutros-Boutros Doggie'],
                                           press_name_ssim: ['Seeing Eye Press']) }
    it "has no citation_publication_date" do
      @monograph_presenter = CurationConcerns::MonographPresenter.new(solr_document, nil)
      render
      expect(rendered).to_not match('citation_publication_date')
    end
  end

  context "with a file_set presenter" do
    let(:solr_document) { SolrDocument.new(id: '001',
                                           has_model_ssim: ['FileSet'],
                                           title_tesim: ['Bark Bark Boop'],
                                           creator_full_name_tesim: ['Mr. Noodles'],
                                           search_year_tesim: ['2011']) }
    it 'has the correct metadata' do
      @presenter = CurationConcerns::FileSetPresenter.new(solr_document, nil)
      render
      expect(rendered).to match('Bark')
      expect(rendered).to match('Noodles')
      expect(rendered).to match('2011')
      expect(rendered).to match('2027/fulcrum.001')
    end
  end

  context "when the file_set has a doi" do
    let(:solr_document) { SolrDocument.new(id: '001',
                                           has_model_ssim: ['FileSet'],
                                           title_tesim: ['Bark Bark Boop'],
                                           creator_full_name_tesim: ['Mr. Noodles'],
                                           search_year_tesim: ['2011'],
                                           doi_ssim: ['https://doi.org/10.3998/fulcrum.001']) }
    it "has the doi metadata (but not the doi url)" do
      @presenter = CurationConcerns::FileSetPresenter.new(solr_document, nil)
      render
      expect(rendered).to match('10.3998/fulcrum.001')
      expect(rendered).to_not match('https://doi.org/')
    end
  end
end
