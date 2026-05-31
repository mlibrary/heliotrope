class SimpleSolrClient::Response::Document
  extend Forwardable
  include Comparable

  attr_accessor :rank

  def <=>(other)
    other = other.score if other.respond_to? :score,
                                             self.score <=> other
  end

  # @!method [](key)
  # @param [String] key The name of the stored field
  # @return [String, Array<String>] the value(s) of the requested field
  def_delegators :@solr_doc_hash, :[], :keys, :values, :to_s

  # !@attribute solr_doc_hash
  #   @return [Hash] the original, un-munged solr data for this document passed into the initializer
  attr_accessor :solr_doc_hash, :rank


  # Create a single document from a Hash representation of the solr return value
  # @param solrdochash [Hash] The ruby-hash representation of a Solr document
  # as returned by a solr query
  def initialize(solrdochash)
    @solr_doc_hash = solrdochash
  end


  # The value of the 'id' field of this document
  def id
    @solr_doc_hash['id']
  end

  # The score of this document on thsi query
  def score
    @solr_doc_hash['score']
  end


  def to_h
    @solr_doc_hash.merge({'_rank' => @rank})
  end

end
