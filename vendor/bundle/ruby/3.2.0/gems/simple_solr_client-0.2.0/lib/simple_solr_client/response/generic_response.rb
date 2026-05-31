require 'forwardable'

module SimpleSolrClient
  module Response
    class GenericResponse
      extend Forwardable
      def_delegators :@solr_response, :[]

      def initialize(solr_response_hash)
        @solr_response = solr_response_hash
      end

      def status
        @solr_response['status']
      end

    end
  end
end
