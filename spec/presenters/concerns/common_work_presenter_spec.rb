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

    def featured_representatives
      []
    end

    delegate :representative_id, :thumbnail_path, to: :@solr_document
  end

  let(:presenter) { self.class::Presenter.new(solr_document) }

  describe '#work_thumbnail' do
    context 'representative_id not set, uses Hyrax default' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], thumbnail_path_ss: '/assets/work.png') }

      it {
        expect(presenter.work_thumbnail).to eq '<img class="img-responsive" src="/assets/work.png" style="max-width:225px" alt="Cover image for ">'
      }
    end

    context 'representative_id set, uses image-service, default width' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: ['999999999']) }

      it {
        expect(presenter.work_thumbnail).to start_with '<img class="img-responsive" src="/image-service/999999999/full/225,/0/default.jpg" alt="Cover image for ">'
      }
    end

    context 'representative_id set, uses image-service, custom width' do
      let(:solr_document) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], hasRelatedMediaFragment_ssim: ['999999999']) }

      it {
        expect(presenter.work_thumbnail(99)).to start_with '<img class="img-responsive" src="/image-service/999999999/full/99,/0/default.jpg" alt="Cover image for ">'
      }
    end
  end

  describe '#assets?' do
    subject { presenter.assets? }

    let(:solr_document) {
      ::SolrDocument.new(id: 'mono',
                         has_model_ssim: ['Monograph'],
                         # representative_id has a rather different Solr name!
                         hasRelatedMediaFragment_ssim: cover.id,
                         ordered_member_ids_ssim: ordered_ids)
    }

    let(:cover) { ::SolrDocument.new(id: 'cover', has_model_ssim: ['FileSet'], visibility_ssi: 'open') }
    let(:blue_file) { ::SolrDocument.new(id: 'blue', has_model_ssim: ['FileSet'], visibility_ssi: 'open') }
    let(:green_file) { ::SolrDocument.new(id: 'green', has_model_ssim: ['FileSet'], visibility_ssi: 'open') }
    let(:red_file) { ::SolrDocument.new(id: 'red', has_model_ssim: ['FileSet'], visibility_ssi: 'restricted') }

    context 'has some open-visibility non-representative assets' do
      let(:ordered_ids) { [cover.id, blue_file.id, green_file.id, red_file.id] }

      before do
        ActiveFedora::SolrService.add([solr_document.to_h, cover.to_h, blue_file.to_h, green_file.to_h, red_file.to_h])
        ActiveFedora::SolrService.commit
      end

      it { is_expected.to be true }
    end

    context 'has no open-visibility non-representative assets' do
      let(:ordered_ids) { [cover.id, red_file.id] }

      before do
        ActiveFedora::SolrService.add([solr_document.to_h, cover.to_h, red_file.to_h])
        ActiveFedora::SolrService.commit
      end

      it { is_expected.to be false }
    end
  end
end
