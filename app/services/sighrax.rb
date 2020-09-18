# frozen_string_literal: true

require_dependency 'sighrax/asset'
require_dependency 'sighrax/electronic_publication'
require_dependency 'sighrax/entity'
require_dependency 'sighrax/interactive_map'
require_dependency 'sighrax/mobipocket'
require_dependency 'sighrax/model'
require_dependency 'sighrax/monograph'
require_dependency 'sighrax/score'
require_dependency 'sighrax/portable_document_format'

module Sighrax # rubocop:disable Metrics/ModuleLength
  class << self
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
      from_solr_document(presenter.solr_document)
    end

    def from_solr_document(document)
      document = document.to_h.with_indifferent_access
      noid = document['id']
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      model_type = Array(document['has_model_ssim']).first
      return Entity.send(:new, noid, document) if model_type.blank?
      model_factory(noid, document, model_type)
    end

    # Actor Helpers

    def ability_can?(actor, action, target)
      return false unless action.is_a?(Symbol)
      return false unless target.valid?
      return false unless Incognito.allow_ability_can?(actor)
      ability = Ability.new(actor.is_a?(User) ? actor : nil)
      ability.can?(action, hyrax_presenter(target, ability))
    end

    def access?(actor, target)
      products = actor_products(actor)
      component = Greensub::Component.find_by(noid: target.noid)
      component_products = component&.products || []
      (products & component_products).any?
    end

    def platform_admin?(actor)
      actor.is_a?(User) && actor.platform_admin? && Incognito.allow_platform_admin?(actor)
    end

    def press_admin?(actor, press)
      return false unless actor.is_a?(User)
      actor.admin_roles.where(resource: press).any?
    end

    def press_editor?(actor, press)
      return false unless actor.is_a?(User)
      actor.editor_roles.where(resource: press).any?
    end

    # Entity Helpers

    def policy(actor, entity)
      EntityPolicy.new(actor, entity)
    end

    def hyrax_presenter(entity, current_ability = nil)
      case entity
      when Monograph
        Hyrax::MonographPresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      when Score
        Hyrax::ScorePresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      when Asset
        Hyrax::FileSetPresenter.new(SolrDocument.new(entity.send(:data)), current_ability)
      else
        Hyrax::Presenter.send(:new, entity.noid)
      end
    end

    def press(entity)
      if entity.is_a?(Sighrax::Monograph)
        Press.find_by(subdomain: Sighrax.hyrax_presenter(entity).subdomain)
      elsif entity.is_a?(Sighrax::Asset)
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
      when Sighrax::Asset
        Rails.application.routes.url_helpers.hyrax_file_set_url(entity.noid)
      else
        nil
      end
    end

    def allow_download?(entity)
      return false unless entity.valid?
      return false unless downloadable?(entity)
      /^yes$/i.match?(Array(solr_document(entity)['allow_download_ssim']).first)
    end

    def deposited?(entity)
      return false unless entity.valid?
      return true if Array(solr_document(entity)['suppressed_bsi']).empty?
      Array(solr_document(entity)['suppressed_bsi']).first.blank?
    end

    def downloadable?(entity)
      return false unless entity.valid?
      return false if Array(solr_document(entity)['external_resource_url_ssim']).first.present?
      entity.is_a?(Sighrax::Asset)
    end

    def open_access?(entity)
      return false unless entity.valid?
      /^yes$/i.match?(Array(solr_document(entity)['open_access_tesim']).first)
    end

    def published?(entity)
      return false unless entity.valid?
      deposited?(entity) && /open/i.match?(Array(solr_document(entity)['visibility_ssi']).first)
    end

    def restricted?(entity)
      return true unless entity.valid?
      Greensub::Component.find_by(noid: entity.noid).present?
    end

    def tombstone?(entity)
      return false unless entity.valid?
      expiration_date = Array(solr_document(entity)['permissions_expiration_date_ssim']).first
      return false if expiration_date.blank?
      Date.parse(expiration_date) <= Time.now.utc.to_date
    end

    def watermarkable?(entity)
      return false unless entity.valid?
      return false if Array(solr_document(entity)['external_resource_url_ssim']).first.present?
      entity.is_a?(Sighrax::PortableDocumentFormat)
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
          when 'epub'
            ElectronicPublication.send(:new, noid, data)
          when 'mobi'
            Mobipocket.send(:new, noid, data)
          when 'pdf_ebook'
            PortableDocumentFormat.send(:new, noid, data)
          else
            Asset.send(:new, noid, data)
          end
        end
      end

      def file_set_resource_type_factory(noid, data)
        case Array(data['resource_type_tesim']).first
        when /^interactive map$/i
          InteractiveMap.send(:new, noid, data)
        else
          Asset.send(:new, noid, data)
        end
      end

      def actor_products(actor)
        if Incognito.sudo_actor?(actor)
          Incognito.sudo_actor_products(actor)
        else
          Greensub.actor_products(actor)
        end
      end

      def solr_document(entity)
        entity.send(:data)
      end
  end
end
