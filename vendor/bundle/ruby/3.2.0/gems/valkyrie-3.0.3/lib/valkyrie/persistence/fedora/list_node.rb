# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Represents a node in an ORE List. Used for persisting ordered members into
  # an Resource Description Framework (RDF) Graph for Fedora, to keep order maintained.
  #
  # RDF graph nodes are used to implement a linked list
  # An RDF hash URI is referenced for the list itself
  # <http://www.iana.org/assignments/relation/first> is the predicate which links to the first element in the list
  # <http://www.iana.org/assignments/relation/last> is the predicate which links to the last element
  # Each element is also referenced using a hash URI
  # <http://www.iana.org/assignments/relation/next> is the predicate which links one element to the next element in the list
  # (This permits unidirectional traversal)
  # <http://www.openarchives.org/ore/terms/proxyFor> is the predicate which links any given element to its value
  # (These can be IRIs or XML literals supported by a graph store)
  #
  # @see http://www.openarchives.org/ore/1.0/datamodel#Proxies
  # @see https://www.iana.org/assignments/link-relations/link-relations.xhtml#link-relations-1
  class ListNode
    attr_reader :rdf_subject, :graph
    attr_writer :next, :prev
    attr_writer :next_uri, :prev_uri
    attr_accessor :proxy_in, :proxy_for
    attr_reader :adapter

    # @param node_cache [Hash] structure used to cache the nodes of the graph
    # @param rdf_subject [RDF::URI] the URI for the linked list in the graph store (usually a hash URI)
    # @param adapter []
    # @param graph [RDF::Repository] the RDF graph storing the structure of the RDF statements
    def initialize(node_cache, rdf_subject, adapter, graph = RDF::Repository.new)
      @rdf_subject = rdf_subject
      @graph = graph
      @node_cache = node_cache
      @adapter = adapter
      Builder.new(rdf_subject, graph).populate(self)
    end

    # Returns the next proxy or a tail sentinel.
    # @return [RDF::URI]
    def next
      @next ||=
        if next_uri
          node_cache.fetch(next_uri) do
            node = self.class.new(node_cache, next_uri, adapter, graph)
            node.prev = self
            node
          end
        end
    end

    # Returns the previous proxy or a head sentinel.
    # @return [RDF::URI]
    def prev
      @prev ||= node_cache.fetch(prev_uri) if prev_uri
    end

    # Graph representation of node.
    # @return [Valkyrie::Persistence::Fedora::ListNode::Resource]
    def to_graph
      return RDF::Graph.new if target_id.blank?
      g = Resource.new(rdf_subject)
      g.proxy_for = target
      g.proxy_in = proxy_in.try(:uri)
      g.next = self.next.try(:rdf_subject)
      g.prev = prev.try(:rdf_subject)
      g.graph
    end

    # @return [RDF::URI] or [String]
    def target
      if target_id.is_a?(Valkyrie::ID)
        adapter.id_to_uri(target_id.to_s)
      else
        target_id
      end
    end

    # @return [String]
    def target_id
      if proxy_for.to_s.include?("/") && proxy_for.to_s.start_with?(adapter.connection_prefix)
        adapter.uri_to_id(proxy_for)
      else
        proxy_for
      end
    end

    private

    attr_reader :next_uri, :prev_uri, :node_cache

    # Class used to populate the RDF graph structure for the linked lists
    class Builder
      attr_reader :uri, :graph

      # @param uri [RDF::URI] the URI for the linked list in the graph store
      # @param graph [RDF::Repository] the RDF graph to be populated
      def initialize(uri, graph)
        @uri = uri
        @graph = graph
      end

      # Populates attributes for the LinkedNode
      # @param instance [ListNode]
      def populate(instance)
        instance.proxy_for = resource.proxy_for
        instance.proxy_in = resource.proxy_in
        instance.next_uri = resource.next
        instance.prev_uri = resource.prev
      end

      private

      # Constructs a set of triples using ActiveTriples as objects
      # @return [Valkyrie::Persistence::Fedora::ListNode::Resource]
      def resource
        @resource ||= Resource.new(uri, graph: graph)
      end
    end

    # Class for providing a set of triples modeling linked list nodes
    class Resource
      def self.property(property, predicate:)
        define_method property do
          graph.query([uri, predicate, nil]).objects.first
        end

        define_method "#{property}=" do |val|
          return if val.nil?
          graph << [uri, predicate, val]
        end
      end

      property :proxy_for, predicate: ::RDF::Vocab::ORE.proxyFor
      property :proxy_in, predicate: ::RDF::Vocab::ORE.proxyIn
      property :next, predicate: ::RDF::Vocab::IANA.next
      property :prev, predicate: ::RDF::Vocab::IANA.prev

      attr_reader :graph, :uri
      def initialize(uri, graph: RDF::Graph.new)
        @uri = uri
        @graph = graph
      end
    end
  end
end
