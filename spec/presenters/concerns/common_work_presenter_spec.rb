# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommonWorkPresenter do
  class self::Presenter # rubocop:disable Style/ClassAndModuleChildren
    include CommonWorkPresenter
    attr_reader :solr_document, :current_ability

    def initialize(solr_document)
      @solr_document = solr_document
      @current_ability = nil
    end

    # It's a little weird that this method is needed to exercise the module by itself, but it's dependent on...
    # FeaturedRepresentatives::MonographPresenter.featured_representatives()
    def featured_representatives
      FeaturedRepresentative.where(work_id: 'mono')
    end

    delegate :representative_id, :thumbnail_path, to: :@solr_document
  end

  let(:presenter) { self.class::Presenter.new(solr_document) }
  let(:title) { presenter.title }

  describe '#thumbnail_tag' do
    subject { presenter.thumbnail_tag(width, options) }

    let(:width) { 225 }
    let(:options) { double('options') }

    context 'representative_id not set, uses Hyrax default' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', title_tesim: ['A Title'], has_model_ssim: ['Monograph'], thumbnail_path_ss: '/assets/work.png') }
      let(:thumbnail_image_tag) { double('thumbnail_image_tag') }

      before do
        allow(ActionController::Base.helpers).to receive(:image_tag).with(presenter.thumbnail_path, options).and_return(thumbnail_image_tag)
        allow(options).to receive(:[]=).with(:style, "max-width: #{width}px")
      end

      it {
        is_expected.to be thumbnail_image_tag
        expect(ActionController::Base.helpers).to have_received(:image_tag).with(presenter.thumbnail_path, options)
        expect(options)                       .to have_received(:[]=).with(:style, "max-width: #{width}px")
      }
    end

    context 'representative_id set, uses image-service' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', title_tesim: ['A Title'], has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: ['999999999']) }
      let(:cache_buster_id) { 'cache_buster_id' }
      let(:riiif_image_path) { Riiif::Engine.routes.url_helpers.image_path(cache_buster_id, "#{width},", format: "png") }
      let(:riiif_image_tag) { double('riiif_image_tag') }

      before do
        allow(presenter).to receive(:cache_buster_id).and_return(cache_buster_id)
        allow(ActionController::Base.helpers).to receive(:image_tag).with(riiif_image_path, options).and_return(riiif_image_tag)
      end

      it {
        is_expected.to be riiif_image_tag
        expect(presenter).to have_received(:cache_buster_id)
        expect(ActionController::Base.helpers).to have_received(:image_tag).with(riiif_image_path, options)
      }
    end
  end

  describe '#poster_tag' do
    subject { presenter.poster_tag(options) }

    let(:options) { double('options') }

    context 'representative_id not set, uses Hyrax default' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', title_tesim: ['A Title'], has_model_ssim: ['Monograph'], thumbnail_path_ss: '/assets/work.png') }
      let(:thumbnail_image_tag) { double('thumbnail_image_tag') }

      before do
        allow(ActionController::Base.helpers).to receive(:image_tag).with(presenter.thumbnail_path, options).and_return(thumbnail_image_tag)
      end

      it {
        is_expected.to be thumbnail_image_tag
        expect(ActionController::Base.helpers).to have_received(:image_tag).with(presenter.thumbnail_path, options)
      }
    end

    context 'representative_id set, uses image-service' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', title_tesim: ['A Title'], has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: ['999999999']) }
      let(:cache_buster_id) { 'cache_buster_id' }
      let(:riiif_image_path) { Riiif::Engine.routes.url_helpers.image_path(cache_buster_id, :full, :full, 0, format: "png") }
      let(:riiif_image_tag) { double('riiif_image_tag') }

      before do
        allow(presenter).to receive(:cache_buster_id).and_return(cache_buster_id)
        allow(ActionController::Base.helpers).to receive(:image_tag).with(riiif_image_path, options).and_return(riiif_image_tag)
      end

      it {
        is_expected.to be riiif_image_tag
        expect(presenter).to have_received(:cache_buster_id)
        expect(ActionController::Base.helpers).to have_received(:image_tag).with(riiif_image_path, options)
      }
    end
  end

  describe '#cache_buster_id' do
    subject { presenter.cache_buster_id }

    let(:solr_document) { ::SolrDocument.new(id: '111111111', title_tesim: ['A Title'], has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: ['999999999']) }

    it { is_expected.to eq presenter.representative_id }

    context "with a thumbnail file" do
      before do
        FileUtils.mkdir_p(File.join(Settings.scratch_space_path, 'rspec_derivatives', '99', '99', '99', '99'))
        FileUtils.touch(File.join(Settings.scratch_space_path, 'rspec_derivatives', '99', '99', '99', '99', '9-thumbnail.jpeg'))
      end

      after do
        FileUtils.rm_rf(Dir[File.join(Settings.scratch_space_path, 'rspec_derivatives')])
      end

      it {
        is_expected.to eq presenter.representative_id + "#{File.mtime(File.join(Settings.scratch_space_path, 'rspec_derivatives', '99', '99', '99', '99', '9-thumbnail.jpeg')).to_i}"
      }
    end
  end

  describe '#license?' do
    subject { presenter.license? }

    let(:solr_document) { instance_double(SolrDocument, 'solr_document', license: [license]) }
    let(:license) { }

    it { is_expected.to be false }

    context 'license' do
      let(:license) { 'license' }

      it { is_expected.to be true }
    end
  end

  describe '#license_alt_text' do
    subject { presenter.license_alt_text }

    let(:solr_document) { instance_double(SolrDocument, 'solr_document', license: [license]) }
    let(:license) { }

    it { is_expected.to eq('Creative Commons License') }

    context 'All Rights Reserved' do
      let(:license) { 'https://www.press.umich.edu/about/licenses#all-rights-reserved' }

      it { is_expected.to eq('All Rights Reserved') }
    end

    context 'http license' do
      let(:license) { 'http://creativecommons.org/publicdomain/zero/1.0/' }

      it { is_expected.to eq 'Creative Commons Zero license (implies pd)' }
    end

    context 'https license' do
      let(:license) { 'https://creativecommons.org/licenses/by-nc-nd/4.0/' }

      it { is_expected.to eq 'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International license' }
    end
  end

  describe '#license_link_content' do
    subject { presenter.license_link_content }

    let(:solr_document) { instance_double(SolrDocument, 'solr_document', license: [license]) }
    let(:license) { }

    it { is_expected.to eq('Creative Commons License') }

    context 'All Rights Reserved' do
      let(:license) { 'https://www.press.umich.edu/about/licenses#all-rights-reserved' }

      it 'returns the correct text, no icon' do
        expect(subject).to be 'All Rights Reserved'
      end
    end

    context 'http license' do
      let(:license) { 'http://creativecommons.org/publicdomain/zero/1.0/' }

      it 'gives the correct logo link' do
        expect(subject).to eq '<img alt="Creative Commons Zero license (implies pd)" style="border-width:0" src="https://i.creativecommons.org/p/zero/1.0/80x15.png"/>'
      end
    end

    context 'https license' do
      let(:license) { 'https://creativecommons.org/licenses/by-nc-nd/4.0/' }

      it 'gives the correct logo link' do
        expect(subject).to eq '<img alt="Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International license" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/80x15.png"/>'
      end
    end
  end
end
