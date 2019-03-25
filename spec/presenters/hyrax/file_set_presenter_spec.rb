# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FileSetPresenter do
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(fileset_doc, ability) }
  let(:dimensionless_presenter) { described_class.new(fileset_doc, ability) }

  describe '#presenters' do
    subject { described_class.new(nil, nil) }

    it do
      is_expected.to be_a TitlePresenter
    end
  end

  describe "#citable_link" do
    context "has a DOI" do
      let(:fileset_doc) {
        SolrDocument.new(id: 'fileset_id',
                         has_model_ssim: ['FileSet'],
                         doi_ssim: ['10.NNNN.N/identifier'])
      }

      it "returns the doi url" do
        expect(presenter.citable_link).to eq HandleService::DOI_ORG_PREFIX + '10.NNNN.N/identifier'
      end
    end

    context "with no DOI" do
      let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet']) }

      it "returns the handle url" do
        expect(presenter.citable_link).to eq HandleService.url(fileset_doc.id)
      end
    end
  end

  describe "#monograph" do
    let(:monograph) { create(:monograph, creator: creator) }
    let(:creator) { ['lastname, firstname'] }
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

    it "has the monograph's creator" do
      expect(presenter.monograph.creator).to match_array(creator)
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

      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'Yes') }

      it { expect(presenter.allow_download?).to be true }
    end

    context 'external resource overrides everything to hide download button' do
      before do
        allow(ability).to receive(:platform_admin?).and_return(true)
        allow(ability).to receive(:can?).with(:edit, 'fs').and_return(true)
      end

      let(:fileset_doc) { SolrDocument.new(id: 'fs', has_model_ssim: ['FileSet'], allow_download_ssim: 'yes', external_resource_url_ssim: 'URL') }

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

  describe '#label' do
    let(:file_set) { create(:file_set, label: 'filename.tif') }
    let(:fileset_doc) { SolrDocument.new(file_set.to_solr) }

    it "returns the label" do
      expect(presenter.label).to eq 'filename.tif'
    end
  end

  describe '#epub?' do
    subject { presenter.epub? }

    let(:fileset_doc) { SolrDocument.new(id: 'fileset_id', monograph_id_ssim: 'monograph_id', has_model_ssim: ['FileSet']) }

    context "featured_representative.kind == 'epub'" do
      let!(:fr) { create(:featured_representative, monograph_id: 'monograph_id', file_set_id: 'fileset_id', kind: 'epub') }

      after { FeaturedRepresentative.destroy_all }

      it { is_expected.to be true }
    end

    context 'not an epub featured_representative' do
      it { is_expected.to be false }
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

    let(:fileset_doc) {
      SolrDocument.new(id: 'fileset_id',
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

    let(:fileset_doc) {
      SolrDocument.new(id: 'fileset_id',
                       has_model_ssim: ['FileSet'],
                       mime_type_ssi: mime_type,
                       external_resource_url_ssim: external_resource_url,
                       thumbnail_path_ss: thumbnail_path)
    }

    context 'file not using a thumbnail derivative' do
      let(:mime_type) { 'application/pdf' }
      let(:external_resource_url) { '' }
      let(:thumbnail_path) { ActionController::Base.helpers.image_path 'default.png' }

      it { is_expected.to be true }
    end

    context 'file using a thumbnail derivative' do
      let(:mime_type) { 'application/pdf' }
      let(:external_resource_url) { '' }
      let(:thumbnail_path) { Hyrax::Engine.routes.url_helpers.download_path('fileset_id', file: 'thumbnail') }

      it { is_expected.to be false }
    end

    context 'external resource' do
      let(:mime_type) { nil }
      let(:external_resource_url) { 'URL' }
      let(:thumbnail_path) { nil }

      it { is_expected.to be true }
    end

    context 'mystery file' do
      let(:mime_type) { nil }
      let(:external_resource_url) { nil }
      let(:thumbnail_path) { nil }

      it { is_expected.to be true }
    end
  end

  describe '#use_riiif_for_icon??' do
    subject { presenter.use_riiif_for_icon? }

    let(:fileset_doc) {
      SolrDocument.new(id: 'fileset_id',
                       has_model_ssim: ['FileSet'],
                       mime_type_ssi: mime_type,
                       external_resource_url_ssim: external_resource_url,
                       thumbnail_path_ss: thumbnail_path)
    }

    context 'file has mime_type that uses hydra-derivatives thumbnail' do
      let(:mime_type) { 'application/pdf' }
      let(:external_resource_url) { '' }
      let(:thumbnail_path) { ActionController::Base.helpers.image_path 'default.png' }

      it { is_expected.to be false }
    end

    context 'file has mime_type that bypasses hydra-derivatives thumbnail creation' do
      let(:mime_type) { 'application/postscript' }
      let(:external_resource_url) { '' }
      let(:thumbnail_path) { 'blah' }

      it { is_expected.to be true }
    end

    context 'external resource' do
      let(:mime_type) { nil }
      let(:external_resource_url) { 'URL' }
      let(:thumbnail_path) { nil }

      it { is_expected.to be false }
    end

    context 'mystery file' do
      let(:mime_type) { nil }
      let(:external_resource_url) { nil }
      let(:thumbnail_path) { nil }

      it { is_expected.to be false }
    end
  end

  describe '#download_button_label' do
    subject { presenter.download_button_label }

    let(:fileset_doc) {
      SolrDocument.new(id: 'fileset_id',
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

    let(:external_resource_url) { '' }
    let(:fileset_doc) { SolrDocument.new(mime_type_ssi: mime_type, external_resource_url_ssim: external_resource_url) }

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
      let(:external_resource_url) { 'URL' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/external_resource' }
    end
  end

  describe '#heliotrope_media_partial for embedded assets' do
    subject { presenter.heliotrope_media_partial('media_display_embedded') }

    let(:fileset_doc) { SolrDocument.new(mime_type_ssi: mime_type, external_resource_url_ssim: '') }

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

  describe "PDF extracted_text download" do
    let(:fileset_doc) { SolrDocument.new(id: id, label_tesim: ['test_pdf.pdf']) }
    let(:id) { double("id") }
    let(:file_set) { double("file_set") }

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:extracted_text).and_return(text_file)
    end

    context "extracted_text_file exists" do
      let(:text_file) do
        Hydra::PCDM::File.new.tap do |f|
          f.content = IO.read(File.join(fixture_path, 'test_pdf.txt'))
          f.original_name = 'long_GUID_thingy.txt'
          f.save!
        end
      end

      context "extracted_text?" do
        subject { presenter.extracted_text? }

        it { is_expected.to be true }
      end

      context "extracted_text_file" do
        subject { presenter.extracted_text_file }

        it { is_expected.to eq text_file }
      end

      context "extracted_text_download_button_label" do
        subject { presenter.extracted_text_download_button_label }

        it { is_expected.to eq 'Download TXT (' + text_file.size.to_s + ' Bytes)' }
      end

      context "extracted_text_download_filename" do
        subject { presenter.extracted_text_download_filename }

        it { is_expected.to eq 'test_pdf.txt' }
      end
    end

    context "extracted_text_file doesn't exist" do
      let(:text_file) { nil }

      context "extracted_text?" do
        subject { presenter.extracted_text? }

        it { is_expected.to be_falsey }
      end
    end
  end
end
