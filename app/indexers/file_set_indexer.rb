class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      # Extra technical metadata we need to index
      # These are apparently not necessarily integers all the time, so index them as symbols
      orig = object.original_file
      if orig.present?
        solr_doc[Solrizer.solr_name('duration', :symbol)] = orig.duration.first if orig.duration.present?
        solr_doc[Solrizer.solr_name('sample_rate', :symbol)] = orig.sample_rate if orig.sample_rate.present?
        solr_doc[Solrizer.solr_name('original_checksum', :symbol)] = orig.original_checksum if orig.original_checksum.present?
        solr_doc[Solrizer.solr_name('original_name', :stored_searchable)] = orig.original_name if orig.original_name.present?
      end

      # Make sure the asset is aware of it's section
      object.in_works.each do |work|
        next unless work.is_a?(Section)
        solr_doc[Solrizer.solr_name('section_title', :stored_searchable)] = work.title
        solr_doc[Solrizer.solr_name('section_title', :facetable)] = work.title
        solr_doc[Solrizer.solr_name('section_id', :symbol)] = work.id
      end
    end
  end
end
