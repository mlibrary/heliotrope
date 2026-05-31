module Ldp
  class Container < Resource::RdfSource
    require 'ldp/container/basic'
    require 'ldp/container/direct'
    require 'ldp/container/indirect'

    def self.for(client, subject, data)
      case
      when data.types.include?(RDF::Vocab::LDP.IndirectContainer)
        Ldp::Container::Indirect.new client, subject, data
      when data.types.include?(RDF::Vocab::LDP.DirectContainer)
        Ldp::Container::Direct.new client, subject, data
      else
        Ldp::Container::Basic.new client, subject, data
      end
    end

    class << self
      alias new_from_response for
    end

    def contains
      @contains ||= Hash[graph.query(predicate: RDF::Vocab::LDP.contains).map do |x|
        [x.object, Ldp::Resource::RdfSource.new(client, x.object, contained_graph(x.object))]
      end]
    end

    ##
    # Add a new resource to the LDP container
    def add *args
      # slug, graph
      # graph
      # slug

      case
      when (args.length > 2 || args.length == 0)

      when (args.length == 2)
        slug, graph_or_content = args
      when (args.first.is_a? RDF::Enumerable)
        slug = nil
        graph_or_content = args.first
      else
        slug = args.first
        graph_or_content = build_empty_graph
      end

      resp = client.post subject, (graph_or_content.is_a?(RDF::Enumerable) ? graph_or_content.dump(:ttl) : graph_or_content) do |req|
        req.headers['Slug'] = slug
      end

      client.find_or_initialize resp.headers['Location']
    end

    private

    def contained_graph subject
      g = RDF::Graph.new
      response_graph.query(subject: subject) do |stmt|
        g << stmt
      end
      g
    end

    def rdf_source_for(object)
      g = contained_graph(object)

      Ldp::Resource::RdfSource.new(client, object, (g unless g.empty?))
    end
  end
end
