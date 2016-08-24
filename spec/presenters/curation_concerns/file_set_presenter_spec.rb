require 'rails_helper'

describe CurationConcerns::FileSetPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(fileset_doc, ability) }
  let(:monograph) { create(:monograph, creator_given_name: "firstname", creator_family_name: "lastname") }
  let(:file_set) { create(:file_set) }
  before do
    monograph.ordered_members << file_set
    monograph.save!
  end

  describe '#allow_download?' do
    let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes') }
    it "can download" do
      expect(presenter.allow_download?).to be true
    end
  end

  describe "#monograph" do
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name.first).to eq monograph.creator_family_name
    end
  end

  describe '#page_title' do
    let(:expected_page_title) { 'Hello' }
    let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], title_tesim: [expected_page_title]) }
    context 'is file set first title' do
      it { expect(presenter.page_title).to eq fileset_doc[:title_tesim].first }
    end
    context 'is expected page title' do
      it { expect(presenter.page_title).to eq expected_page_title }
    end
  end
end
