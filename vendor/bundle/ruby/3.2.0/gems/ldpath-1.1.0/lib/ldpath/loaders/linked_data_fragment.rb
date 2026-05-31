require 'cgi'

class Ldpath::Loaders::LinkedDataFragment
  NEXT_PAGE = RDF::URI('http://www.w3.org/ns/hydra/core#nextPage')

  def initialize(endpoint)
    @endpoint = endpoint
  end

  def load(uri)
    Ldpath.logger.debug "Loading LDF data for #{uri.inspect}"

    graph = RDF::Graph.new
    request_uri = RDF::URI("#{@endpoint}?subject=#{CGI::escape(uri)}")

    while request_uri
      Ldpath.logger.debug " -- querying #{request_uri}"
      request_graph = RDF::Graph.load(request_uri)
      graph.insert_statements(request_graph)
      request_uri = request_graph.first_object([request_uri, NEXT_PAGE, nil])
    end

    graph
  end
end
