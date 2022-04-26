# frozen_string_literal: true

class ScoreIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      existing_fileset_order = existing_filesets
      solr_doc['ordered_member_ids_ssim'] = object.ordered_member_ids
      solr_doc['representative_id_ssim'] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)
    end
  end

  def existing_filesets
    existing_score_doc = ActiveFedora::SolrService.query("{!terms f=id}#{object.id}", rows: 1)
    order = existing_score_doc.blank? ? [] : existing_score_doc[0]['ordered_member_ids_ssim']
    order || []
  end

  def trigger_fileset_reindexing(existing_fileset_order, new_fileset_order)
    new_fileset_order.each_with_index do |id, new_index|
      former_position = existing_fileset_order.index(id)
      next unless former_position && former_position != new_index
      UpdateIndexJob.perform_later(id)
    end
  end
end
