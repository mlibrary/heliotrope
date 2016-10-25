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

  it 'includes TitlePresenter' do
    expect(described_class.new(nil, nil)).to be_a TitlePresenter
  end

  describe "handles" do
    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], ext_url_doi_or_handle: ["Handle"], hdl_ssim: ["HANDLE"]) }
    it "has a handle" do
      expect(presenter.hdl.first).to eq 'HANDLE'
      expect(presenter.handle_url).to eq "http://hdl.handle.net/2027/fulcrum.HANDLE"
      expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.HANDLE"
    end
    it "does not have a handle" do
      fileset_doc.to_h['hdl_ssim'][0] = nil
      # right now we're defaulting to the NOID for new things that don't yet have handles
      expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.fileset_id"
    end
  end

  describe "#monograph" do
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name.first).to eq monograph.creator_family_name
    end
  end

  describe '#allow_download?' do
    let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes') }
    it "can download" do
      expect(presenter.allow_download?).to be true
    end
  end
end
