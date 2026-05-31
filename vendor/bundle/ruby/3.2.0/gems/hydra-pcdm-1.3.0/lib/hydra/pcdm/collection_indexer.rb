module Hydra::PCDM
  class CollectionIndexer < PCDMIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Config.indexing_collection_ids_key] = object.ordered_collection_ids
      end
    end
  end
end
