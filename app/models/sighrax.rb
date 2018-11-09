# frozen_string_literal: true

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

      model_type = entity["has_model_ssim"]&.first
      return Entity.send(:new, noid, entity) if model_type.blank?
      model_factory(noid, entity, model_type)
    end

    private

      def model_factory(noid, entity, model_type)
        if /Monograph/i.match?(model_type)
          Monograph.send(:new, noid, entity)
        elsif /FileSet/i.match?(model_type)
          asset_factory(noid, entity)
        else
          Model.send(:new, noid, entity)
        end
      end

      def asset_factory(noid, entity)
        featured_representative = ::FeaturedRepresentative.find_by(file_set_id: noid)
        return Asset.send(:new, noid, entity) if featured_representative.blank?
        featured_representative_factory(noid, entity, featured_representative)
      end

      def featured_representative_factory(noid, entity, featured_representative)
        if /epub/i.match?(featured_representative.kind)
          ElectronicPublication.send(:new, noid, entity)
        else
          FeaturedRepresentative.send(:new, noid, entity)
        end
      end
  end
end

#
# Require Relative
#
require_relative './sighrax/asset'
require_relative './sighrax/electronic_publication'
require_relative './sighrax/entity'
require_relative './sighrax/model'
require_relative './sighrax/monograph'
