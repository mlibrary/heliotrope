require 'rails_helper'

RSpec.describe 'hyrax/file_sets/show' do
  let(:ability) { double("ability") }
  let(:monograph) { create(:monograph) }
  let(:file_set) { create(:file_set) }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability) }

  before do
    def view.parent
      monograph
    end

    def view.parent_path(_)
      "/concern/monographs/{monograph.id}"
    end

    view.extend Hyrax::FileSetHelper

    monograph.ordered_members << file_set
    monograph.save!
    assign(:presenter, file_set_presenter)
    allow(ability).to receive(:platform_admin?).and_return(false)
    allow(file_set_presenter).to receive(:embed_code).and_return("embed code")
    allow(view).to receive(:parent).and_return(monograph)
    allow(view).to receive(:can?).with(:edit, file_set_presenter).and_return(false)
    stub_template "hyrax/file_sets/_media.html.erb" => "render nothing"
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

  context 'multiple sections per FileSet, appearing in order in FileSets/ordered_members section_title fields' do
    let(:file_set1) { create(:file_set, section_title: ['Chapter 1']) }
    let(:file_set2) { create(:file_set, section_title: ['Chapter 2']) }
    let(:file_set3) { create(:file_set, section_title: ['Chapter 3']) }
    let(:file_set) { create(:file_set, section_title: ['Chapter 3', 'Chapter 1', 'Chapter 2']) }

    it 'infers the correct order from the FileSets\' section_titles to show the order correctly' do
      monograph.ordered_members = []
      monograph.ordered_members << file_set1 << file_set2 << file_set3 << file_set
      monograph.save!
      render
      expect(rendered).to have_css('ul.tabular.list-unstyled li.attribute.section_title', count: 3)
      expect(rendered).to match(/.*Chapter 1.*Chapter 2.*Chapter 3.*/)
      expect(rendered).to_not match(/.*Chapter 3.*Chapter 1.*Chapter 2.*/)
    end
  end

  context 'multiple sections per FileSet, occurring out-of-order in FileSets\'/ordered_members\' section_title fields' do
    let(:monograph) { create(:monograph, section_titles: "Chapter 1\nChapter 2\nChapter3") }
    let(:file_set) { create(:file_set, section_title: ['Chapter 3', 'Chapter 1']) }

    it 'uses monograph section_titles to show the order correctly' do
      monograph.ordered_members = []
      monograph.ordered_members << file_set
      monograph.save!
      render
      expect(rendered).to have_css('ul.tabular.list-unstyled li.attribute.section_title', count: 2)
      expect(rendered).to match(/Chapter 1.*Chapter 3/)
      expect(rendered).to_not match(/Chapter 3.*Chapter 1/)
    end
  end
end
