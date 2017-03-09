class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      # resource_type is not sortable, but we want it to be
      solr_doc[Solrizer.solr_name('resource_type', :sortable)] = object.resource_type

      # Extra technical metadata we need to index
      # These are apparently not necessarily integers all the time, so index them as symbols
      index_technical_metadata(solr_doc, object.original_file) if object.original_file.present?

      object.in_works.each do |work|
        index_monograph_metadata(solr_doc, work) if work.is_a?(Monograph)
      end

      index_monograph_position(solr_doc) unless object.in_works.blank?
      unless object.sort_date.blank?
        solr_doc[Solrizer.solr_name('search_year', :sortable)] = object.sort_date[0, 4]
        solr_doc[Solrizer.solr_name('search_year', :facetable)] = object.sort_date[0, 4]
      end
    end
  end

  def index_technical_metadata(solr_doc, orig)
    solr_doc[Solrizer.solr_name('duration', :symbol)] = orig.duration.first if orig.duration.present?
    solr_doc[Solrizer.solr_name('sample_rate', :symbol)] = orig.sample_rate if orig.sample_rate.present?
    solr_doc[Solrizer.solr_name('original_checksum', :symbol)] = orig.original_checksum if orig.original_checksum.present?
    solr_doc[Solrizer.solr_name('original_name', :stored_searchable)] = orig.original_name if orig.original_name.present?
  end

  # Make sure the asset is aware of its monograph
  def index_monograph_metadata(solr_doc, work)
    solr_doc[Solrizer.solr_name('monograph_id', :symbol)] = work.id
  end

  def index_monograph_position(solr_doc)
    # try to walk back to get the monograph's id
    parent = object.in_works.first
    # avoid nil errors here on first pass of reindex_everything if parent not yet indexed
    return if parent.blank?

    fileset_order = parent.ordered_member_ids

    solr_doc['monograph_position_isi'] = fileset_order.index(object.id) unless fileset_order.blank?
  end
end
