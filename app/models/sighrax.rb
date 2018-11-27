# frozen_string_literal: true

require_relative './sighrax/asset'
require_relative './sighrax/electronic_publication'
require_relative './sighrax/entity'
require_relative './sighrax/model'
require_relative './sighrax/monograph'

module Sighrax
  class << self
    def factory(noid)
      noid = noid&.to_s
      return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

      entity = begin
                 ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
               rescue StandardError => _e
                 nil
               end
      return Entity.null_entity(noid) if entity.blank?

      model_type = entity['has_model_ssim']&.first
      return Entity.send(:new, noid, entity) if model_type.blank?
      model_factory(noid, entity, model_type)
    end

    def hyrax_can?(actor, action, target)
      return false if actor.is_a?(Anonymous)
      return false unless /read/i.match?(action.to_s)
      return false unless target.valid?
      ability = Ability.new(actor)
      ability.can?(action.to_s.to_sym, target.noid)
    end

    def published?(entity)
      entity.valid? && entity['suppressed_bsi'] == false && /open/i.match?(entity['visibility_ssi'])
    end

    def restricted?(entity)
      entity.valid? && Component.find_by(noid: entity.noid).present?
    end

    private

      def model_factory(noid, entity, model_type)
        if /Monograph/i.match?(model_type)
          Monograph.send(:new, noid, entity)
        elsif /FileSet/i.match?(model_type)
          file_set_factory(noid, entity)
        else
          Model.send(:new, noid, entity)
        end
      end

      def file_set_factory(noid, entity)
        featured_representative = FeaturedRepresentative.find_by(file_set_id: noid)
        return Asset.send(:new, noid, entity) if featured_representative.blank?
        case featured_representative.kind
        when 'epub'
          ElectronicPublication.send(:new, noid, entity)
        else
          Asset.send(:new, noid, entity)
        end
      end
  end
end
