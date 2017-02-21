require 'rails_helper'

RSpec.describe "embed/show.html.erb", type: :view do
  let(:file_set) { create(:file_set, title: ['file_set']) }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { CurationConcerns::FileSetPresenter.new(file_set_doc, nil) }

  before do
    assign(:presenter, file_set_presenter)
  end

  context 'image' do
    before do
      render
    end
    it { expect(rendered).to have_tag('img') }
  end
end
