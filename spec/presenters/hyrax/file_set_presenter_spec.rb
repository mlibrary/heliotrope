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
    let(:cover) { create(:file_set) }
    let(:file_set) { create(:file_set) }
    let(:press) { create(:press, subdomain: 'blue') }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set
      monograph.save!
    end

    it "has a monograph" do
      expect(presenter.monograph).to be_an_instance_of(Hyrax::MonographPresenter)
    end

    it "has it's monograph's id" do
      expect(presenter.monograph.id).to eq monograph.id
    end

    it "has the monograph's creator_family_name" do
      expect(presenter.monograph.creator_family_name).to eq monograph.creator_family_name
    end
  end

  describe '#allow_download?' do
    context 'allow_download != "yes"' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(false)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(false)
      end
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'no') }
      it { expect(presenter.allow_download?).to be false }
    end
    context 'allow_download == "yes"' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(false)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(false)
      end
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes') }
      it { expect(presenter.allow_download?).to be true }
    end
    context 'external resource overrides everything to hide download button' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(true)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(true)
      end
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes', external_resource_ssim: 'yes') }
      it { expect(presenter.allow_download?).to be false }
    end
    context 'user has edit privileges' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(false)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(true)
      end
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'no') }
      it { expect(presenter.allow_download?).to be true }
    end
    context 'user is a platform admin' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(true)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(false)
      end
      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'no') }
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
            <iframe src='#{presenter.embed_link}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:56.25%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='#{presenter.embed_link}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:400px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:75%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:generic_embed_code) {
      "<iframe src='#{presenter.embed_link}' style='display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; max-height:400px; margin:auto'></iframe>"
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

  describe '#glyphicon_type' do
    subject { presenter.glyphicon_type }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id',
                                         has_model_ssim: ['FileSet'],
                                         mime_type_ssi: mime_type,
                                         resource_type_tesim: resource_type)
    }

    context 'pdf file' do
      let(:mime_type) { 'application/pdf' }
      let(:resource_type) { nil }
      it { is_expected.to be 'glyphicon glyphicon-file' }
    end
    context 'text resource_type' do
      let(:mime_type) { nil }
      let(:resource_type) { ['text'] }
      it { is_expected.to be 'glyphicon glyphicon-file' }
    end
    context 'image resource_type' do
      let(:mime_type) { nil }
      let(:resource_type) { ['image'] }
      it { is_expected.to be 'glyphicon glyphicon-picture' }
    end
    context 'video resource_type' do
      let(:mime_type) { nil }
      let(:resource_type) { ['video'] }
      it { is_expected.to be 'glyphicon glyphicon-film' }
    end
    context 'audio resource_type' do
      let(:mime_type) { nil }
      let(:resource_type) { ['audio'] }
      it { is_expected.to be 'glyphicon glyphicon-volume-up' }
    end
    context 'mystery file' do
      let(:mime_type) { nil }
      let(:resource_type) { ['blurb'] }
      it { is_expected.to be 'glyphicon glyphicon-file' }
    end
  end

  describe '#use_glyphicon?' do
    subject { presenter.use_glyphicon? }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id',
                                         has_model_ssim: ['FileSet'],
                                         mime_type_ssi: mime_type,
                                         external_resource_ssim: external_resource,
                                         thumbnail_path_ss: thumbnail_path)
    }

    context 'file not using a thumbnail derivative' do
      let(:mime_type) { 'application/pdf' }
      let(:external_resource) { 'no' }
      let(:thumbnail_path) { ActionController::Base.helpers.image_path 'default.png' }
      it { is_expected.to be true }
    end
    context 'file using a thumbnail derivative' do
      let(:mime_type) { 'application/pdf' }
      let(:external_resource) { 'no' }
      let(:thumbnail_path) { Hyrax::Engine.routes.url_helpers.download_path('fileset_id', file: 'thumbnail') }
      it { is_expected.to be false }
    end
    context 'external resource' do
      let(:mime_type) { nil }
      let(:external_resource) { 'yes' }
      let(:thumbnail_path) { nil }
      it { is_expected.to be true }
    end
    context 'mystery file' do
      let(:mime_type) { nil }
      let(:external_resource) { nil }
      let(:thumbnail_path) { nil }
      it { is_expected.to be true }
    end
  end

  describe '#download_button_label' do
    subject { presenter.download_button_label }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id',
                                         has_model_ssim: ['FileSet'],
                                         label_tesim: label,
                                         file_size_lts: file_size)
    }

    context 'size and file extension (from label)' do
      let(:label) { ['Blah.mp4'] }
      let(:file_size) { 55_308_883 }
      it { is_expected.to eq 'Download MP4 (52.7 MB)' }
    end

    context 'size only' do
      let(:label) { nil }
      let(:file_size) { 55_308_883 }
      it { is_expected.to eq 'Download (52.7 MB)' }
    end

    context 'file extension/label only' do
      let(:label) { ['Blah.mp4'] }
      let(:file_size) { nil }
      it { is_expected.to eq 'Download MP4' }
    end

    context 'neither file extension nor label' do
      let(:label) { nil }
      let(:file_size) { nil }
      it { is_expected.to eq 'Download' }
    end
  end

  describe '#heliotrope_media_partial' do
    subject { presenter.heliotrope_media_partial }
    let(:external_resource) { 'no' }
    let(:fileset_doc) { SolrDocument.new(mime_type_ssi: mime_type, external_resource_ssim: external_resource) }
    context "with an image" do
      let(:mime_type) { 'image/tiff' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/leaflet_image' }
    end
    context "with a video" do
      let(:mime_type) { 'video/webm' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/video' }
    end
    context "with an audio" do
      let(:mime_type) { 'audio/wav' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/audio' }
    end
    context "with a pdf" do
      let(:mime_type) { 'application/pdf' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/default' }
    end
    context "with a word document" do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/default' }
    end
    context "with any other file" do
      let(:mime_type) { 'application/binary' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/default' }
    end
    context "with an external resource" do
      let(:mime_type) { nil }
      let(:external_resource) { 'yes' }
      it { is_expected.to eq 'hyrax/file_sets/media_display/external_resource' }
    end
  end

  describe '#heliotrope_media_partial for embedded assets' do
    subject { presenter.heliotrope_media_partial('media_display_embedded') }
    let(:fileset_doc) { SolrDocument.new(mime_type_ssi: mime_type, external_resource_ssim: 'no') }
    context "with an image" do
      let(:mime_type) { 'image/tiff' }
      it { is_expected.to eq 'hyrax/file_sets/media_display_embedded/leaflet_image' }
    end
    context "with a video" do
      let(:mime_type) { 'video/webm' }
      it { is_expected.to eq 'hyrax/file_sets/media_display_embedded/video' }
    end
    context "with any other file" do
      let(:mime_type) { 'application/binary' }
      it { is_expected.to eq 'hyrax/file_sets/media_display_embedded/default' }
    end
  end
end
