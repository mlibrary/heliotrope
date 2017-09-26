# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FileSetPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(fileset_doc, ability) }
  let(:dimensionless_presenter) { described_class.new(fileset_doc, ability) }

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

      it "has that explicit handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.a.handle"
      end
    end

    context "with no DOI and no explicit handle" do
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet']) }

      it "has the default NOID based handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.fileset_id"
      end
    end
  end

  describe "#monograph" do
    let(:monograph) { create(:monograph, creator_given_name: "firstname", creator_family_name: "lastname") }
    let(:file_set) { create(:file_set) }
    let(:press) { create(:press, subdomain: 'blue') }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end

    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name).to eq monograph.creator_family_name
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

  describe '#allow_embed?' do
    let(:press) { create(:press) }
    let(:monograph) { create(:monograph, press: press.subdomain) }
    let(:file_set) { create(:file_set) }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end

    context 'no' do
      before { allow(ability).to receive(:platform_admin?).and_return(false) }
      it { expect(presenter.allow_embed?).to be false }
    end
    context 'yes' do
      before { allow(ability).to receive(:platform_admin?).and_return(true) }
      it { expect(presenter.allow_embed?).to be true }
    end
  end

  describe '#embed_code' do
    let(:image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'><!-- actual image height: 1080px -->
            <iframe src='http://#{Settings.host}/embed?hdl=#{CGI.escape(HandleService.handle(presenter))}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='http://#{Settings.host}/embed?hdl=#{CGI.escape(HandleService.handle(presenter))}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:56.25%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='http://#{Settings.host}/embed?hdl=#{CGI.escape(HandleService.handle(presenter))}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:75%; position:relative; height:0;'>
            <iframe src='http://#{Settings.host}/embed?hdl=#{CGI.escape(HandleService.handle(presenter))}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:generic_embed_code) {
      "<iframe src='http://#{Settings.host}/embed?hdl=#{CGI.escape(HandleService.handle(presenter))}' style='display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; max-height:400px; margin:auto'></iframe>"
    }
    before do
      allow(presenter).to receive(:width).and_return(1920)
      allow(presenter).to receive(:height).and_return(1080)
      allow(dimensionless_presenter).to receive(:width).and_return('')
      allow(dimensionless_presenter).to receive(:height).and_return('')
    end

    context 'image FileSet' do
      let(:mime_type) { 'image/tiff' }
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }
      it { expect(presenter.embed_code).to eq image_embed_code }
    end
    context 'video FileSet' do
      let(:mime_type) { 'video/mp4' }
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }
      it { expect(presenter.embed_code).to eq video_embed_code }
    end
    context 'dimensionless image FileSet' do
      let(:mime_type) { 'image/tiff' }
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }
      it { expect(dimensionless_presenter.embed_code).to eq dimensionless_image_embed_code }
    end
    context 'dimensionless video FileSet' do
      let(:mime_type) { 'video/mp4' }
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }
      it { expect(dimensionless_presenter.embed_code).to eq dimensionless_video_embed_code }
    end
    context 'non-media FileSet' do
      let(:mime_type) { 'application/pdf' }
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }
      it { expect(presenter.embed_code).to eq generic_embed_code }
    end
  end

  describe '#epub?' do
    subject { presenter.epub? }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }

    context 'text/plain' do
      let(:mime_type) { 'text/plain' }
      it { is_expected.to be false }
    end
    context 'application/epub+zip' do
      let(:mime_type) { 'application/epub+zip' }
      it { is_expected.to be true }
    end
  end

  describe '#manifest?' do
    subject { presenter.manifest? }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type) }

    context 'text/plain' do
      let(:mime_type) { 'text/plain' }
      it { is_expected.to be false }
    end
    context 'text/csv' do
      let(:mime_type) { 'text/csv' }
      it { is_expected.to be true }
    end
    context 'text/comma-separated-values' do
      let(:mime_type) { 'text/comma-separated-values' }
      it { is_expected.to be true }
    end
  end

  describe '#file' do
    subject { presenter.file }

    let(:fileset_doc) { SolrDocument.new(id: id) }
    let(:id) { double("id") }
    let(:file_set) { double("file_set") }

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:original_file).and_return(file)
    end

    context 'nil' do
      let(:file) { nil }
      it { expect { subject }.to  raise_error("FileSet #[Double \"id\"] original file is nil.") }
    end
    context 'file' do
      let(:file) { double("file") }
      it { is_expected.to eq file }
    end
  end
end
