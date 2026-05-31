require 'simple_solr_client/response/query_response'

module SimpleSolrClient::Core::Search

  def fv_search(field, value)
    v = value
    v = SimpleSolrClient.lucene_escape Array(value).join(' ') unless v == '*'
    kv = "#{field}:(#{v})"
    get('select', {:q => kv}, SimpleSolrClient::Response::QueryResponse)
  end

  def all
    fv_search('*', '*')
  end

  def id(i)
    fv_search('id', i).first
  end


end
