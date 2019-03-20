# frozen_string_literal: true

require_dependency 'sighrax/asset'
require_dependency 'sighrax/electronic_publication'
require_dependency 'sighrax/entity'
require_dependency 'sighrax/mobipocket'
require_dependency 'sighrax/model'
require_dependency 'sighrax/monograph'
require_dependency 'sighrax/portable_document_format'

module Sighrax
  class << self
    def factory(noid)
      noid = noid&.to_s
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      data = begin
               ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
             rescue StandardError => _e
               nil
             end
      return Entity.null_entity(noid) if data.blank?

      model_type = data['has_model_ssim']&.first
      return Entity.send(:new, noid, data) if model_type.blank?
      model_factory(noid, data, model_type)
    end

    def access?(actor, target)
      products = actor_products(actor)
      component = Component.find_by(noid: target.noid)
      component_products = component&.products || []
      (products & component_products).any?
    end

    def allow_download?(entity)
      return false unless entity.valid?
      return false unless downloadable?(entity)
      /^yes$/i.match?(entity.data['allow_download_ssim']&.first)
    end

    def deposited?(entity)
      return false unless entity.valid?
      return true if entity.data['suppressed_bsi'].blank?
      entity.data['suppressed_bsi'].blank?
    end

    def downloadable?(entity)
      return false unless entity.valid?
      return false if entity.data['external_resource_url_ssim'].present?
      entity.is_a?(Sighrax::Asset)
    end

    def hyrax_can?(actor, action, target)
      return false if actor.is_a?(Anonymous)
      return false unless action.is_a?(Symbol)
      return false unless target.valid?
      return false unless Incognito.allow_hyrax_can?(actor)
      ability = Ability.new(actor)
      ability.can?(action, target.noid)
    end

    def open_access?(entity)
      return false unless entity.valid?
      /^yes$/i.match?(entity.data['open_access_tesim']&.first)
    end

    def platform_admin?(actor)
      actor.is_a?(User) && actor.platform_admin? && Incognito.allow_platform_admin?(actor)
    end

    def published?(entity)
      return false unless entity.valid?
      deposited?(entity) && /open/i.match?(entity.data['visibility_ssi'])
    end

    def restricted?(entity)
      return true unless entity.valid?
      Component.find_by(noid: entity.noid).present?
    end

    private

      def model_factory(noid, data, model_type)
        if /^Monograph$/i.match?(model_type)
          Monograph.send(:new, noid, data)
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
  end
end
