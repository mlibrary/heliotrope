# frozen_string_literal: true

require_dependency 'sighrax/audiobook_ebook'
require_dependency 'sighrax/ebook'
require_dependency 'sighrax/entity'
require_dependency 'sighrax/epub_ebook'
require_dependency 'sighrax/interactive_map'
require_dependency 'sighrax/mobi_ebook'
require_dependency 'sighrax/model'
require_dependency 'sighrax/monograph'
require_dependency 'sighrax/null_entity'
require_dependency 'sighrax/pdf_ebook'
require_dependency 'sighrax/platform'
require_dependency 'sighrax/publisher'
require_dependency 'sighrax/resource'
require_dependency 'sighrax/score'
require_dependency 'sighrax/work'

module Sighrax # rubocop:disable Metrics/ModuleLength
  class << self
    # Factories

    def from_noid(noid)
      noid = noid&.to_s
      data = begin
        ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
      rescue StandardError => _e
        nil
      end
      return Entity.null_entity(noid) if data.blank?

      from_solr_document(data)
    end

    def from_presenter(presenter)
      from_solr_document(presenter&.solr_document)
    end

    def from_solr_document(document)
      document = document.to_h.with_indifferent_access
      noid = document['id']
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      model_type = Array(document['has_model_ssim']).first
      return Entity.send(:new, noid, document) if model_type.blank?
      model_factory(noid, document, model_type)
    end

    def platform
      Platform.send(:new)
    end

    # Greensub Helpers

    def allow_read_products
      Greensub::Institution.find_by(identifier: Settings.world_institution_identifier)&.products || []
    end

    # Role Helpers

    def platform_admin?(actor)
      return false unless actor.is_a?(User)

      actor.platform_admin? && Incognito.allow_platform_admin?(actor)
    end

    def press_role?(actor, press)
      return false unless actor.is_a?(User)

      actor.press_roles.where(resource: press).any?
    end

    def press_admin?(actor, press)
      return false unless actor.is_a?(User)

      actor.admin_roles.where(resource: press).any?
    end

    def press_editor?(actor, press)
      return false unless actor.is_a?(User)

      actor.editor_roles.where(resource: press).any?
    end

    def press_analyst?(actor, press)
      return false unless actor.is_a?(User)

      actor.analyst_roles.where(resource: press).any?
    end

    # Entity Helpers

    def hyrax_presenter(entity, current_ability = nil)
      case entity
      when Monograph
        Hyrax::MonographPresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      when Score
        Hyrax::ScorePresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      when Resource
        Hyrax::FileSetPresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      else
        Hyrax::Presenter.send(:new, entity.noid)
      end
    end

    def press(entity)
      if entity.is_a?(Sighrax::Monograph)
        Press.find_by(subdomain: Sighrax.hyrax_presenter(entity).subdomain)
      elsif entity.is_a?(Sighrax::Resource)
        if entity.parent.is_a?(Sighrax::Monograph)
          Press.find_by(subdomain: Sighrax.hyrax_presenter(entity.parent).subdomain)
        else
          Press.null_press
        end
      else
        Press.null_press
      end
    end

    def url(entity)
      case entity
      when Sighrax::Monograph
        Rails.application.routes.url_helpers.hyrax_monograph_url(entity.noid)
      when Sighrax::Score
        Rails.application.routes.url_helpers.hyrax_score_url(entity.noid)
      when Sighrax::Resource
        Rails.application.routes.url_helpers.hyrax_file_set_url(entity.noid)
      else
        nil
      end
    end

    private

      def model_factory(noid, data, model_type)
        if /^Monograph$/i.match?(model_type)
          Monograph.send(:new, noid, data)
        elsif /^Score$/i.match?(model_type)
          Score.send(:new, noid, data)
        elsif /^FileSet$/i.match?(model_type)
          file_set_factory(noid, data)
        else
          Model.send(:new, noid, data)
        end
      end

      def file_set_factory(noid, data)
        featured_representative = FeaturedRepresentative.find_by(file_set_id: noid)
        if featured_representative.blank?
          file_set_resource_type_factory(noid, data)
        else
          case featured_representative.kind
          when 'audiobook'
            AudiobookEbook.send(:new, noid, data)
          when 'epub'
            EpubEbook.send(:new, noid, data)
          when 'mobi'
            MobiEbook.send(:new, noid, data)
          when 'pdf_ebook'
            PdfEbook.send(:new, noid, data)
          else
            Resource.send(:new, noid, data)
          end
        end
      end

      def file_set_resource_type_factory(noid, data)
        case Array(data['resource_type_tesim']).first
        when /^interactive map$/i
          InteractiveMap.send(:new, noid, data)
        else
          Resource.send(:new, noid, data)
        end
      end
  end
end
