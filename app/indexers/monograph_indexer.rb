class MonographIndexer < CurationConcerns::WorkIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      # grab previous file set order here from Solr (before they are reindexed)
      existing_fileset_order = existing_filesets
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids
      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name
      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id
      trigger_fileset_reindexing(existing_fileset_order, object.ordered_member_ids)
    end
  end

  def existing_filesets
    existing_monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{object.id}")
    order = existing_monograph_doc.blank? ? [] : existing_monograph_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)]
    order || []
  end

  def trigger_fileset_reindexing(existing_fileset_order, new_fileset_order)
    new_fileset_order.each_with_index do |id, new_index|
      former_position = existing_fileset_order.index(id)
      next unless former_position && former_position != new_index
      # ReindexFileSetJob.perform_later(FileSet.find(id))
      FileSet.find(id).update_index
    end
  end
end
