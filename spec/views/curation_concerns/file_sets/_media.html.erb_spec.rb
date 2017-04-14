require 'rails_helper'

RSpec.describe 'curation_concerns/file_sets/_media', type: :view do
  let(:file_set) { build(:file_set,
                         id: 'fileset_id',
                         title: ['Things'],
                         caption: ['Stuff'],
                         has_model: ['FileSet'],
                         external_resource: 'yes',
                         ext_url_doi_or_handle: 'http://things.at/stuff') }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:ability) { double('ability') }
  let(:request) { double }
  let(:file_set_presenter) { CurationConcerns::FileSetPresenter.new(file_set_doc, ability, request) }

  context 'with an external_resource' do
    it 'has the external resource url' do
      assign(:presenter, file_set_presenter)
      render
      expect(rendered).to match('<a href="http://things.at/stuff" title=')
    end
  end
end
