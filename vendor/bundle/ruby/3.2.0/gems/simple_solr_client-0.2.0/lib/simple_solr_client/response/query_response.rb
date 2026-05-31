require 'simple_solr_client/response/generic_response'
require 'simple_solr_client/response/document'

class SimpleSolrClient::Response::QueryResponse < SimpleSolrClient::Response::GenericResponse
  extend Forwardable
  include Enumerable

  attr_reader :num_found, :docs, :first_index, :docs, :params, :page

  def_delegators :@docs, :each, :count, :size
  def_delegators :@indexed_docs, :[]

  def initialize(solr_response)
    super
    resp         = @solr_response['response']
    @num_found   = resp['numFound']
    @first_index = resp['start'] + 1

    @docs         = []
    @indexed_docs = {}
    resp['docs'].each_with_index do |d, i|
      doc_rank = i + @first_index
      doc      = SimpleSolrClient::Response::Document.new(d)
      doc.rank = doc_rank
      @docs << doc
      @indexed_docs[doc.id] = doc
    end
  end

  def last_index
    @first_index + @num_found
  end

  def rank(id)
    @indexed_docs[id.to_s].rank
  end

  def score(id)
    @indexed_docs[id.to_s].score
  end

  # @return [Boolean] True if there are no documents
  def empty?
    @docs.empty?
  end


  def each_with_rank
    return self.enum_for(:each_with_rank) unless block_given?
    @docs.each { |x| yield x, x.rank }
  end

end

