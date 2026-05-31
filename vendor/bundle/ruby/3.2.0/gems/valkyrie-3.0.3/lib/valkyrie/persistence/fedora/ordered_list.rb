# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Ruby object representation of an ORE doubly linked list.
  # Used in the Fedora adapter for persisting ordered members.
  class OrderedList
    include Enumerable
    attr_reader :graph, :head_subject, :tail_subject, :adapter
    attr_writer :head, :tail
    delegate :each, to: :ordered_reader
    delegate :length, to: :to_a

    # @param [::RDF::Enumerable] graph Enumerable where ORE statements are
    #   stored.
    # @param [::RDF::URI] head_subject URI of head node in list.
    # @param [::RDF::URI] tail_subject URI of tail node in list.
    def initialize(graph, head_subject, tail_subject, adapter)
      @graph = graph
      @head_subject = head_subject
      @tail_subject = tail_subject
      @node_cache ||= NodeCache.new
      @adapter = adapter
      @changed = false
      tail
    end

    # @return [HeadSentinel] Sentinel for the top of the list. If not empty,
    #  head.next is the first element.
    def head
      @head ||= HeadSentinel.new(self, next_node: build_node(head_subject))
    end

    # @return [TailSentinel] Sentinel for the bottom of the list. If not
    #   empty, tail.prev is the first element.
    def tail
      @tail ||=
        if tail_subject
          TailSentinel.new(self, prev_node: build_node(tail_subject))
        else
          head.next
        end
    end

    # @param [Integer] loc Location to insert target at
    # @param [String] proxy_for proxyFor to add
    def insert_proxy_for_at(loc, proxy_for, proxy_in: nil)
      node = build_node(new_node_subject)
      node.proxy_for = proxy_for
      node.proxy_in = proxy_in
      if loc.zero?
        append_to(node, head)
      else
        append_to(node, ordered_reader.take(loc).last)
      end
    end

    # @return [::RDF::Graph] Graph representation of this list.
    def to_graph
      ::RDF::Graph.new.tap do |g|
        array = to_a
        array.map(&:to_graph).each do |resource_graph|
          g << resource_graph
        end
      end
    end

    private

    attr_reader :node_cache

    # Append a node to a linked list
    # @param source [ListNode] the node being appended
    # @param append_node [ListNode] the node already in the existing list
    def append_to(source, append_node)
      source.prev = append_node
      append_node.next.prev = source
      source.next = append_node.next
      append_node.next = source
      @changed = true
    end

    # Constructs a new OrderedReader for this OrderedList
    # @return [OrderedReader]
    def ordered_reader
      OrderedReader.new(self)
    end

    # Populates the list with constructed ListNode Objects
    # @param subject [RDF::URI]
    def build_node(subject = nil)
      return nil unless subject
      node_cache.fetch(subject) do
        ListNode.new(node_cache, subject, adapter, graph)
      end
    end

    # Generates hash URIs for the subject of the LinkedList
    # Should one of these URIs already be in use, a new URI will be generated
    # @return [RDF::URI]
    def new_node_subject
      node = ::RDF::URI("##{::RDF::Node.new.id}")
      node = ::RDF::URI("##{::RDF::Node.new.id}") while node_cache.key?(node)
      node
    end

    # Class used for caching LinkedNode objects mapped to URIs
    class NodeCache
      def initialize
        @cache ||= {}
      end

      # Retrieve the ListNode for a given URI
      # If a block is passed, set its output to the cache
      # @param uri [RDF::URI]
      # @return [ListNode]
      def fetch(uri)
        @cache[uri] ||= yield if block_given?
      end

      # Determines whether or not the cache contains a key
      # @param key [Object]
      # @return [Boolean]
      def key?(key)
        @cache.key?(key)
      end
    end

    # Class modeling sentinels within the linked list
    # @see https://en.wikipedia.org/wiki/Sentinel_value
    class Sentinel
      attr_reader :parent, :next, :prev
      attr_writer :next, :prev

      # @param parent [Valkyrie::Persistence::Fedora::OrderedList]
      # @param next_node [ListNode]
      # @param prev_node [ListNode]
      def initialize(parent, next_node: nil, prev_node: nil)
        @parent = parent
        @next = next_node
        @prev = prev_node
      end

      # Ensure that this always behaves like a NilClass
      # @return [TrueClass]
      def nil?
        true
      end

      # Ensure that this does not have a URI
      # @return [NilClass]
      def rdf_subject
        nil
      end
    end

    class HeadSentinel < Sentinel
      # @param parent [Valkyrie::Persistence::Fedora::OrderedList]
      # @param next_node [ListNode]
      # @param prev_node [ListNode]
      def initialize(*args, **kwargs)
        super
        @next ||= TailSentinel.new(parent, prev_node: self)
      end
    end

    class TailSentinel < Sentinel
      # @param parent [Valkyrie::Persistence::Fedora::OrderedList]
      # @param next_node [ListNode]
      # @param prev_node [ListNode]
      def initialize(*args, **kwargs)
        super
        prev.next = self if prev&.next != self
      end
    end
  end
end
