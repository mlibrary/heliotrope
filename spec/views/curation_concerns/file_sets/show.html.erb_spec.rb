require 'rails_helper'

describe 'curation_concerns/file_sets/show', type: :view do
  before do
    def view.parent
      nil
    end
  end

  let(:expected_title) { 'markdown' }
  let(:expected_title_with_emphasis_markdown) { '_' + expected_title + '_' }
  let(:monograph) { create(:monograph) }
  let(:file_set) { create(:file_set, title: [expected_title_with_emphasis_markdown]) }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { CurationConcerns::FileSetPresenter.new(file_set_doc, nil) }

  before do
    monograph.ordered_members << file_set
    monograph.save!
    assign(:presenter, file_set_presenter)
  end

  context 'render markdown' do
    before do
      render
    end
    it 'file set title' do
      expect(rendered).to have_tag('em', text: expected_title)
    end
  end
end
