# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CitationsBehavior do
  describe 'when a monograph has enough information to generate citations' do
    context 'PDF with DOI' do
      let(:doc) do
        SolrDocument.new(id: '111111111',
                         creator_tesim: ['Pugner, Mark', 'Princely, Mary'],
                         title_tesim: ['The Complete Book of Everything'],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'],
                         doi_ssim: ['10.0000/mpub.111111'])
      end
      let(:rep) { create(:featured_representative, work_id: '111111111', file_set_id: '123456789', kind: 'epub') }
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }

      it 'returns the correct APA citation' do
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">Pugner, M., &amp; Princely, M.</span> (2001). <i class="citation-title">The Complete Book of Everything.</i> https://doi.org/10.0000/mpub.111111.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark, and Mary Princely.</span> <i class="citation-title">The Complete Book of Everything.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://doi.org/10.0000/mpub.111111.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark, and Mary Princely. </span><i class="citation-title">The Complete Book of Everything.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://doi.org/10.0000/mpub.111111. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end

    context 'EBOOK without DOI' do
      let(:doc) do
        SolrDocument.new(id: '222222222',
                         creator_tesim: ['Pugner, Mark', 'Princely, Mary'],
                         title_tesim: ['The Complete Book of Everything'],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'])
      end
      let!(:rep) { create(:featured_representative, work_id: '222222222', file_set_id: '123456789', kind: 'pdf_ebook') } # rubocop:disable RSpec/LetSetup
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }

      it 'returns the correct APA citation' do
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">Pugner, M., &amp; Princely, M.</span> (2001). <i class="citation-title">The Complete Book of Everything.</i> Retrieved from https://hdl.handle.net/2027/fulcrum.222222222.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark, and Mary Princely.</span> <i class="citation-title">The Complete Book of Everything.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://hdl.handle.net/2027/fulcrum.222222222. PDF.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark, and Mary Princely. </span><i class="citation-title">The Complete Book of Everything.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://hdl.handle.net/2027/fulcrum.222222222. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end

    # https://tools.lib.umich.edu/jira/browse/HELIO-3186
    context 'Corporate author name as first citation author' do
      let(:doc) do
        SolrDocument.new(id: '333333333',
                         creator_tesim: ['BIG MUSEUM', 'Pugner, Mark', 'Princely, Mary'],
                         title_tesim: ['The Complete Book of Big Museum'],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'])
      end
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }

      it 'returns the correct APA citation' do
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">BIG MUSEUM, Pugner, M., &amp; Princely, M.</span> (2001). <i class="citation-title">The Complete Book of Big Museum.</i> Retrieved from https://hdl.handle.net/2027/fulcrum.333333333.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">BIG MUSEUM, Mark Pugner, and Mary Princely.</span> <i class="citation-title">The Complete Book of Big Museum.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://hdl.handle.net/2027/fulcrum.333333333.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">BIG MUSEUM, Mark Pugner, and Mary Princely. </span><i class="citation-title">The Complete Book of Big Museum.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://hdl.handle.net/2027/fulcrum.333333333. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end

    # https://tools.lib.umich.edu/jira/browse/HELIO-3186
    context 'Corporate author name as citation author other than first' do
      let(:doc) do
        SolrDocument.new(id: '444444444',
                         creator_tesim: ['Princely, Mary', 'BIG MUSEUM', 'Pugner, Mark'],
                         title_tesim: ['The Complete Book of Big Museum'],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'])
      end
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }

      it 'returns the correct APA citation' do
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">Princely, M., BIG MUSEUM, &amp; Pugner, M.</span> (2001). <i class="citation-title">The Complete Book of Big Museum.</i> Retrieved from https://hdl.handle.net/2027/fulcrum.444444444.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">Princely, Mary, BIG MUSEUM, and Mark Pugner.</span> <i class="citation-title">The Complete Book of Big Museum.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://hdl.handle.net/2027/fulcrum.444444444.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">Princely, Mary, BIG MUSEUM, and Mark Pugner. </span><i class="citation-title">The Complete Book of Big Museum.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://hdl.handle.net/2027/fulcrum.444444444. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end

    context 'MLA structure for watermarking' do
      let(:doc) do
        SolrDocument.new(id: '444444444',
                         creator_tesim: ['Princely, Mary', "BIGG'S MUSEUM", 'Pugner, Mark'],
                         title_tesim: ["The Complete Book of Bigg's Museum"],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'])
      end
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }
      let(:structure) { export_as_mla_structure(presenter) }

      it 'returns the correct MLA structure author without HTML escaping' do
        expect(structure[:author]).to eq("Princely, Mary, BIGG'S MUSEUM, and Mark Pugner. ")
      end
      it 'returns the correct MLA structure title without HTML escaping' do
        expect(structure[:title]).to eq("The Complete Book of Bigg's Museum.")
      end
      it 'returns the correct MLA citation' do
        expect(structure[:publisher]).to eq('E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://hdl.handle.net/2027/fulcrum.444444444. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end
  end
end
