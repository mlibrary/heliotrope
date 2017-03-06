require 'rails_helper'

describe CurationConcerns::FileSetPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(fileset_doc, ability) }

  it 'includes TitlePresenter' do
    expect(described_class.new(nil, nil)).to be_a TitlePresenter
  end

  describe "#citable_link" do
    context "with a DOI" do
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], doi_ssim: ['http://doi.and.things']) }
      it "has a DOI" do
        expect(presenter.citable_link).to eq 'http://doi.and.things'
      end
    end

    context "with an explicit handle and no DOI" do
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], hdl_ssim: ['a.handle']) }
      it "it has that explicit handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.a.handle"
      end
    end

    context "with no DOI and no explicit handle" do
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet']) }
      it "it has the default NOID based handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.fileset_id"
      end
    end
  end

  describe "#monograph" do
    let(:monograph) { create(:monograph, creator_given_name: "firstname", creator_family_name: "lastname") }
    let(:file_set) { create(:file_set) }
    let(:press) { create(:press, subdomain: 'blue') }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name.first).to eq monograph.creator_family_name
    end
  end

  describe '#allow_download?' do
    context 'no' do
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'no') }
      it { expect(presenter.allow_download?).to be false }
    end
    context 'yes' do
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes') }
      it { expect(presenter.allow_download?).to be true }
    end
  end

  describe '#subdomain' do
    let(:fileset_doc) { SolrDocument.new(id: 'fs', press_tesim: 'yellow') }
    it "returns the press subdomain" do
      expect(presenter.subdomain).to eq 'yellow'
    end
  end

  describe '#label' do
    let(:file_set) { create(:file_set, label: 'filename.tif') }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it "returns the label" do
      expect(presenter.label).to eq 'filename.tif'
    end
  end

  describe '#embed_code' do
    let(:file_set) { create(:file_set) }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }
    it { expect(presenter.embed_code).to eq "<iframe src='http://#{Settings.host}/embed?hdl=#{HandleService.handle(presenter)}' height='500' width='500'>Your browser doesn't support iframes!</iframe>" }
  end
end
