# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CitationsBehavior do
  describe 'when a monograph has enough information to generate citations' do
    context 'PDF with DOI' do
      let(:doc) do
        SolrDocument.new(id: '111111111',
                         creator_tesim: ['Pugner, Mark'],
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
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">Pugner, M.</span> (2001). <i class="citation-title">The Complete Book of Everything.</i> https://doi.org/10.0000/mpub.111111.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark.</span> <i class="citation-title">The Complete Book of Everything.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://doi.org/10.0000/mpub.111111. EPUB.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark. </span><i class="citation-title">The Complete Book of Everything.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://doi.org/10.0000/mpub.111111. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end

    context 'EBOOK without DOI' do
      let(:doc) do
        SolrDocument.new(id: '111111111',
                         creator_tesim: ['Pugner, Mark'],
                         title_tesim: ['The Complete Book of Everything'],
                         location_tesim: ['Ann Arbor, MI'],
                         publisher_tesim: ['University of Michigan Press'],
                         has_model_ssim: ['Monograph'],
                         date_created_tesim: ['2001'])
      end
      let!(:rep) { create(:featured_representative, work_id: '111111111', file_set_id: '123456789', kind: 'pdf_ebook') } # rubocop:disable RSpec/LetSetup
      let(:presenter) { Hyrax::MonographPresenter.new(doc, nil) }

      it 'returns the correct APA citation' do
        expect(export_as_apa_citation(presenter)).to eq('<span class="citation-author">Pugner, M.</span> (2001). <i class="citation-title">The Complete Book of Everything.</i> Retrieved from https://hdl.handle.net/2027/fulcrum.111111111.')
      end
      it 'returns the correct Chicago citation' do
        expect(export_as_chicago_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark.</span> <i class="citation-title">The Complete Book of Everything.</i> Ann Arbor, MI: University of Michigan Press, 2001. https://hdl.handle.net/2027/fulcrum.111111111. PDF.')
      end
      it 'returns the correct MLA citation' do
        expect(export_as_mla_citation(presenter)).to eq('<span class="citation-author">Pugner, Mark. </span><i class="citation-title">The Complete Book of Everything.</i> E-book, Ann Arbor, MI: University of Michigan Press, 2001, https://hdl.handle.net/2027/fulcrum.111111111. Accessed ' + "#{Time.now.getlocal.strftime('%e %b %Y').strip}.")
      end
    end
  end
end
