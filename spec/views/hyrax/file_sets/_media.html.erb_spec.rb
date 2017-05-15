require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_media', type: :view do
  let(:file_set) { build(:file_set,
                         id: 'fileset_id',
                         title: ['Things'],
                         caption: ['Stuff'],
                         has_model: ['FileSet'],
                         external_resource: 'yes',
                         ext_url_doi_or_handle: 'http://things.at/stuff') }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:ability) { double('ability') }
  let(:request) { double('request') }
  let(:file_set_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability, request) }

  context 'with an external_resource' do
    it 'has the external resource url' do
      assign(:presenter, file_set_presenter)
      render
      expect(rendered).to match('<a href="http://things.at/stuff" title=')
    end
  end

  context 'with an epub' do
    let(:alt_text) { double('alt_text') }
    let(:present) { double('present') }
    before do
      allow(alt_text).to receive(:first).and_return('alt_text')
      allow(file_set_presenter).to receive(:alt_text).and_return(alt_text)
      allow(file_set_presenter).to receive(:external_resource).and_return('no')
      allow(file_set_presenter).to receive(:image?).and_return(false)
      allow(file_set_presenter).to receive(:epub?).and_return(true)
      allow(present).to receive(:present?).and_return(false)
      allow(file_set_presenter).to receive(:transcript).and_return(present)
      allow(file_set_presenter).to receive(:translation).and_return(present)
    end
    it do
      assign(:presenter, file_set_presenter)
      stub_template("hyrax/file_sets/media_display/_epub.html.erb" => "epub")
      render
      expect(rendered).to match(/epub/)
    end
  end
end
