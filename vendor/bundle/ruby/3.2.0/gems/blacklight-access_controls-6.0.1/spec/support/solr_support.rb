# frozen_string_literal: true

module SolrSupport
  def create_solr_doc(hash)
    doc = SolrDocument.new(hash)
    solr = Blacklight.default_index.connection
    solr.add(doc)
    solr.commit
    doc
  end
end
