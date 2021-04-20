# frozen_string_literal: true

module TombstonePresenter
  extend ActiveSupport::Concern

  delegate :tombstone, to: :solr_document

  def tombstone?
    /^yes$/i.match?(tombstone)
  end

  def tombstone_message
    Sighrax.from_solr_document(solr_document).tombstone_message
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
