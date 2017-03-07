require 'rails_helper'

describe 'curation_concerns/file_sets/show', type: :view do
  before do
    def view.parent
      nil
    end
  end

  let(:monograph) { create(:monograph) }
  let(:file_set) { create(:file_set) }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { CurationConcerns::FileSetPresenter.new(file_set_doc, nil) }

  before do
    monograph.ordered_members << file_set
    monograph.save!
    assign(:presenter, file_set_presenter)
    allow(file_set_presenter).to receive(:embed_code).and_return("embed code")
    allow(view).to receive(:parent).and_return(monograph)
    allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(false)
  end

  context 'render markdown' do
    let(:expected_title) { 'markdown' }
    let(:expected_title_with_emphasis_markdown) { '_' + expected_title + '_' }
    let(:file_set) { create(:file_set, title: [expected_title_with_emphasis_markdown]) }
    before { render }
    it { expect(rendered).to have_tag('em', text: expected_title) }
  end

  context 'form-actions' do
    context 'no edit and no download' do
      before do
        allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(false)
        allow(file_set_presenter).to receive(:allow_download?).and_return(false)
        render
      end
      it { expect(rendered).to_not have_link('Download') }
    end
    context 'no edit and download' do
      before do
        allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(false)
        allow(file_set_presenter).to receive(:allow_download?).and_return(true)
        render
      end
      it { expect(rendered).to have_link('Download') }
    end
    context 'edit and no download' do
      before do
        allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(true)
        allow(file_set_presenter).to receive(:allow_download?).and_return(false)
        render
      end
      it { expect(rendered).to have_link('Download') }
    end
    context 'edit and download' do
      before do
        allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(true)
        allow(file_set_presenter).to receive(:allow_download?).and_return(true)
        render
      end
      it { expect(rendered).to have_link('Download') }
    end
  end
end
