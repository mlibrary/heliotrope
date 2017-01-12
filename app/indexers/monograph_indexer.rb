class MonographIndexer < CurationConcerns::WorkIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('ordered_member_ids', :symbol)] = object.ordered_member_ids

      press = Press.find_by(subdomain: object.press)
      press_name = press.name unless press.nil?
      solr_doc[Solrizer.solr_name('press_name', :symbol)] = press_name

      solr_doc[Solrizer.solr_name('representative_id', :symbol)] = object.representative_id

      existing_fileset_order = existing_filesets
      new_fileset_order = index_ordered_fileset_ids(solr_doc)
      trigger_fileset_reindexing(existing_fileset_order, new_fileset_order)
    end
  end

  def existing_filesets
    existing_monograph_doc = ActiveFedora::SolrService.query("{!terms f=id}#{object.id}")
    existing_monograph_doc.blank? ? [] : existing_monograph_doc[0][Solrizer.solr_name('ordered_fileset_ids', :symbol)]
  end

  def index_ordered_fileset_ids(solr_doc)
    all_monograph_fileset_ids = []
    object.ordered_members.to_a.each do |monograph_member|
      if monograph_member.is_a?(Section)
        section_doc = ActiveFedora::SolrService.query("{!terms f=id}#{monograph_member.id}")
        next if section_doc.blank?
        section_ids = section_doc[0][Solrizer.solr_name('ordered_member_ids', :symbol)]
        next if section_ids.blank?
        section_ids.each do |section_member_id|
          # assume no subsections, nothing recursive for now
          all_monograph_fileset_ids << section_member_id
        end
      else
        all_monograph_fileset_ids << monograph_member.id
      end
    end
    solr_doc[Solrizer.solr_name('ordered_fileset_ids', :symbol)] = all_monograph_fileset_ids
  end

  def trigger_fileset_reindexing(existing_fileset_order, new_fileset_order)
    # this should never happen, I don't think, even on reindex_everything
    return if existing_fileset_order.blank?

    new_fileset_order.each_with_index do |id, new_index|
      former_position = existing_fileset_order.index(id)
      next unless former_position && former_position != new_index
      # the new order won't be set on the monograph's Solr doc until this...
      # indexer (super) finishes, so stick these on a perform_later job
      ReindexFileSetJob.perform_later(FileSet.find(id))
    end
  end
end
