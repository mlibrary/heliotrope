# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Acts as a null object representing the default case for paginating over solr
  # results. Often only used for the first iteration of a loop, or to retrieve
  # all Documents in an index.
  class DefaultPaginator
    # Default parameter for the next page in search results in a Solr query request
    # @see https://lucene.apache.org/solr/guide/pagination-of-results.html
    # @return [Integer]
    def next_page
      1
    end

    # Default parameter for the number of documents in a page of search results in a Solr query request
    # @see https://lucene.apache.org/solr/guide/pagination-of-results.html
    # @return [Integer]
    def per_page
      100
    end

    # Default state for the whether or not additional pages of search results in a Solr query response exist
    # @see https://lucene.apache.org/solr/guide/pagination-of-results.html
    # @return [Boolean]
    def has_next?
      true
    end
  end
end
