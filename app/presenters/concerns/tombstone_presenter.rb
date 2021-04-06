# frozen_string_literal: true

module TombstonePresenter
  extend ActiveSupport::Concern

  delegate :tombstone, to: :solr_document

  def tombstone?
    /^yes$/i.match?(tombstone)
  end

  # The recursive flag is necessary to support the importer and exporter
  def tombstone_message(recursive = false)
    model = Sighrax.from_solr_document(solr_document)
    return model.tombstone_message unless recursive

    model.tombstone_message ||
      model.publisher.tombstone_message ||
        Sighrax.platform.tombstone_message
  end

  def tombstone_thumbnail?
    return true unless respond_to?(:representative_id)
    Sighrax.from_noid(representative_id).tombstone?
  end

  def tombstone_thumbnail_tag(width, options = {})
    options[:style] = "max-width: #{width}px"
    ActionController::Base.helpers.image_tag('tombstone.svg', options)
  end
end
