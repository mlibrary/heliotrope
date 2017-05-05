require 'rails_helper'

RSpec.describe 'curation_concerns/file_sets/show' do
  let(:monograph) { create(:monograph) }
  let(:file_set) { create(:file_set) }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { CurationConcerns::FileSetPresenter.new(file_set_doc, nil) }

  before do
    def view.parent
      monograph
    end

    def view.parent_path(_)
      "/concern/monographs/{monograph.id}"
    end

    monograph.ordered_members << file_set
    monograph.save!
    assign(:presenter, file_set_presenter)
    allow(file_set_presenter).to receive(:embed_code).and_return("embed code")
    allow(view).to receive(:parent).and_return(monograph)
    allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(false)
    stub_template "curation_concerns/file_sets/_media.html.erb" => "render nothing"
  end

  context 'render markdown' do
    let(:expected_title) { 'markdown' }
    let(:expected_title_with_emphasis_markdown) { '_' + expected_title + '_' }
    let(:file_set) { create(:file_set, title: [expected_title_with_emphasis_markdown]) }

    it {
      render
      expect(rendered).to have_tag('em', text: expected_title)
    }
  end

  context 'form-actions' do
    let(:can_edit) { false }
    let(:allow_download) { false }
    let(:allow_embed) { false }
    before do
      allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(can_edit)
      allow(file_set_presenter).to receive(:allow_download?).and_return(allow_download)
      allow(file_set_presenter).to receive(:allow_embed?).and_return(allow_embed)
      render
    end
    context 'download' do
      context 'no edit and no download' do
        it { expect(rendered).to_not have_link('Download') }
      end
      context 'no edit and download' do
        let(:allow_download) { true }
        it { expect(rendered).to have_link('Download') }
      end
      context 'edit and no download' do
        let(:can_edit) { true }
        it { expect(rendered).to have_link('Download') }
      end
      context 'edit and download' do
        let(:can_edit) { true }
        let(:allow_download) { true }
        it { expect(rendered).to have_link('Download') }
      end
    end
    context 'embedcode' do
      context 'no edit and no embed' do
        it { expect(rendered).to_not match(/embedcode/) }
      end
      context 'no edit and embed' do
        let(:allow_embed) { true }
        it { expect(rendered).to match(/embedcode/) }
      end
      context 'edit and no embed' do
        let(:can_edit) { true }
        it { expect(rendered).to match(/embedcode/) }
      end
      context 'edit and embed' do
        let(:can_edit) { true }
        let(:allow_embed) { true }
        it { expect(rendered).to match(/embedcode/) }
      end
    end
  end
end
