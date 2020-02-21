# frozen_string_literal: true

require_dependency 'sighrax/asset'
require_dependency 'sighrax/electronic_publication'
require_dependency 'sighrax/entity'
require_dependency 'sighrax/mobipocket'
require_dependency 'sighrax/model'
require_dependency 'sighrax/monograph'
require_dependency 'sighrax/score'
require_dependency 'sighrax/portable_document_format'

module Sighrax # rubocop:disable Metrics/ModuleLength
  class << self
    def factory(noid)
      noid = noid&.to_s
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      data = begin
               ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
             rescue StandardError => _e
               nil
             end

      Rails.logger.debug("[SIGHRAX] Solr get #{noid}")
      return Entity.null_entity(noid) if data.blank?

      model_type = Array(data['has_model_ssim']).first
      return Entity.send(:new, noid, data) if model_type.blank?
      model_factory(noid, data, model_type)
    end

    # Since we're starting to add logic to Sighrax that we want in different
    # contexts (tombstone and subscription access, etc) we'll add different factories
    # so we don't need redundant solr calls to get the same information.
    def solr_factory(document)
      document = document.to_h.with_indifferent_access
      noid = document['id']
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      model_type = document['has_model_ssim'].first
      return Entity.send(:new, noid, data) if model_type.blank?
      model_factory(noid, document, model_type)
    end

    def presenter_factory(presenter)
      noid = presenter.id
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      model_type = presenter.solr_document['has_model_ssim'].first
      return Entity.send(:new, noid, data) if model_type.blank?
      model_factory(noid, presenter.solr_document, model_type)
    end

    def policy(current_actor, entity)
      EntityPolicy.new(current_actor, entity)
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

    def hyrax_presenter(entity)
      if entity.is_a?(Sighrax::Monograph)
        Hyrax::MonographPresenter.new(SolrDocument.new(entity.send(:data)), nil)
      elsif entity.is_a?(Sighrax::Score)
        Hyrax::ScorePresenter.new(SolrDocument.new(entity.send(:data)), nil)
      elsif entity.is_a?(Sighrax::Asset)
        Hyrax::FileSetPresenter.new(SolrDocument.new(entity.send(:data)), nil)
      else
        Hyrax::Presenter.send(:new, entity.noid)
      end
    end

    # Checkpoint Helpers

    def access?(actor, target)
      products = actor_products(actor)
      component = Greensub::Component.find_by(noid: target.noid)
      component_products = component&.products || []
      (products & component_products).any?
    end

    def hyrax_can?(actor, action, target)
      return false if actor.is_a?(Anonymous)
      return false unless action.is_a?(Symbol)
      return false unless target.valid?
      return false unless Incognito.allow_hyrax_can?(actor)
      ability = Ability.new(actor)
      ability.can?(action, target.noid)
    end

    # Role Helpers

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
        return Asset.send(:new, noid, data) if featured_representative.blank?

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
