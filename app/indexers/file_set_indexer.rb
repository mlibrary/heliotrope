class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      # resource_type is not sortable, but we want it to be
      solr_doc[Solrizer.solr_name('resource_type', :sortable)] = object.resource_type

      # Extra technical metadata we need to index
      # These are apparently not necessarily integers all the time, so index them as symbols
      index_technical_metadata(solr_doc, object.original_file) if object.original_file.present?

      # Make sure the asset is aware of it's section and it's monograph
      object.in_works.each do |work|
        index_monograph_metadata(solr_doc, work) if work.is_a?(Monograph)
        index_section_metadata(solr_doc, work) if work.is_a?(Section)
      end
    end
  end

  def index_technical_metadata(solr_doc, orig)
    solr_doc[Solrizer.solr_name('duration', :symbol)] = orig.duration.first if orig.duration.present?
    solr_doc[Solrizer.solr_name('sample_rate', :symbol)] = orig.sample_rate if orig.sample_rate.present?
    solr_doc[Solrizer.solr_name('original_checksum', :symbol)] = orig.original_checksum if orig.original_checksum.present?
    solr_doc[Solrizer.solr_name('original_name', :stored_searchable)] = orig.original_name if orig.original_name.present?
  end

  def index_monograph_metadata(solr_doc, work)
    solr_doc[Solrizer.solr_name('monograph_id', :symbol)] = work.id
  end

  def index_section_metadata(solr_doc, work)
    solr_doc[Solrizer.solr_name('section_title', :stored_searchable)] = work.title
    solr_doc[Solrizer.solr_name('section_title', :facetable)] = work.title
    solr_doc[Solrizer.solr_name('section_id', :symbol)] = work.id
    solr_doc[Solrizer.solr_name('monograph_id', :symbol)] = work.monograph_id
  end
end
