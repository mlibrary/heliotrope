# frozen_string_literal: true

module Sighrax
  def self.factory(noid) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    noid = noid&.to_s

    return Entity.null_entity(noid) unless ValidationService.valid_noid?(noid)

    entity = begin
      ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
    rescue StandardError => _e
      nil
    end
    return Entity.null_entity(noid) if entity.blank?

    model_type = entity["has_model_ssim"]&.first

    if model_type.blank?
      Entity.send(:new, noid, entity)
    elsif /Monograph/i.match?(model_type)
      Monograph.send(:new, noid, entity)
    elsif /FileSet/i.match?(model_type)
      sub_type = FeaturedRepresentative.find_by(file_set_id: noid)
      if sub_type.blank?
        Asset.send(:new, noid, entity)
      else
        case sub_type.kind
        when 'epub'
          ElectronicPublication.send(:new, noid, entity)
        else
          Asset.send(:new, noid, entity)
        end
      end
    else
      Model.send(:new, noid, entity)
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
