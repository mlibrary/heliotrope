class FileSetIndexer < CurationConcerns::FileSetIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      object.in_works.each do |work|
        solr_doc[Solrizer.solr_name('section_title', :stored_searchable)] = work.title if work.is_a?(Section)
        solr_doc[Solrizer.solr_name('section_title', :facetable)] = work.title if work.is_a?(Section)
        solr_doc[Solrizer.solr_name('section_id', :symbol)] = work.id if work.is_a?(Section)
      end
    end
  end
end
