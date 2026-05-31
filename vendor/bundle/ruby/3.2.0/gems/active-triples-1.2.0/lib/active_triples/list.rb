# frozen_string_literal: true
module ActiveTriples
  ##
  # An implementation of RDF::List intregrated with ActiveTriples.
  #
  # A thoughtful reflection period is encouraged before using the
  # rdf:List concept in your data. The community may pursue other
  # options for ordered sets.
  class List < RDF::List
    include ActiveTriples::NestedAttributes
    extend Configurable
    include Properties
    include Reflection

    delegate :rdf_subject, :mark_for_destruction, :marked_for_destruction?, :set_value, :get_values, :parent, :persist, :persist!, :type, :dump, :attributes=, to: :resource
    alias_method :to_ary, :to_a

    class << self
      def from_uri(uri, vals)
        list = ListResource.from_uri(uri, vals)
        self.new(subject: list.rdf_subject, graph: list)
      end
    end

    def resource
      graph
    end

    def initialize(subject: nil, graph: nil, values: nil, &block)
      super
      @graph = ListResource.new(subject) unless
        graph.kind_of? RDFSource
      @graph << parent if parent
      @graph.list = self
      @graph.reload
    end

    def clear
      graph.send :erase_old_resource
      old_subject = subject
      super
      @subject = old_subject
      @graph = ListResource.new(subject)
      graph.list = self
    end

    def []=(idx, value)
      raise IndexError "index #{idx} too small for array: minimum 0" if idx < 0

      if idx >= length
        (idx - length).times do
          self << RDF::OWL.Nothing
        end
        return self << value
      end
      each_subject.with_index do |v, i|
        next unless i == idx
        resource.set_value(v, RDF.first, value)
      end
    end

    ##
    # Override to return AF::Rdf::Resources as values, where
    # appropriate.
    def each(&block)
      return super unless block_given?
      super { |value| yield node_from_value(value) }
    end

    ##
    # Do these like #each.
    def first
      node_from_value(super)
    end

    ##
    # find an AF::Rdf::Resource from the value returned by RDF::List
    def node_from_value(value)
      return value unless value.is_a? RDF::Resource
      return value if value.is_a? RDFSource

      type_uri = resource.query([value, RDF.type, nil]).to_a.first.try(:object)
      klass = RDFSource.type_registry[type_uri]
      klass ||= Resource

      klass.from_uri(value, resource)
    end

    ##
    # This class is the graph/Resource that backs the List and
    # supplies integration with the rest of ActiveTriples
    class ListResource
      include ActiveTriples::RDFSource

      attr_reader :list

      def list=(list)
        @list ||= list
      end

      def reflections
        @list.class
      end

      def attributes=(values)
        raise ArgumentError, "values must be a Hash, you provided #{values.class}" unless values.kind_of? Hash
        values.with_indifferent_access.each do |key, value|
          if reflections.properties.keys.map { |k| "#{k}_attributes" }.include?(key)
            klass = reflections.reflect_on_property(key[0..-12])['class_name']
            klass = ActiveTriples.class_from_string(klass, final_parent.class) if klass.is_a? String
            value.is_a?(Hash) ? attributes_hash_to_list(values[key], klass) : attributes_to_list(value, klass)
            values.delete key
          end
        end
        super
      end

      protected

      # Clear out any old assertions in the repository about this node or statement
      # thus preparing to receive the updated assertions.
      def erase_old_resource
        RDF::List.new(subject: rdf_subject, graph: self).clear
      end

      private

        def attributes_to_list(value, klass)
          value.each do |entry|
            item = klass.new()
            item.attributes = entry
            list << item
          end
        end

        def attributes_hash_to_list(value, klass)
          value.each do |counter, attr|
            item = klass.new()
            item.attributes = attr if attr
            list[counter.to_i] = item
          end
        end
    end

    ##
    # Monkey patch to allow lists to have subject URIs.
    # Overrides RDF::List to prevent URI subjects
    # from being replaced with nodes.
    #
    # @NOTE Lists built this way will return false for #valid?
    def <<(value)
      value = case value
        when nil         then RDF.nil
        when RDF::Value  then value
        when Array       then RDF::List.new(nil, graph, value)
        else value
      end

      if subject == RDF.nil
        @subject = RDF::Node.new
        @graph = ListResource.new(subject)
        @graph.list = self
        @graph.type = RDF.List
      end

      if empty?
        @graph.type = RDF.List
        resource.set_value(RDF.first, value)
        resource.insert([subject.to_term, RDF.rest, RDF.nil])
        resource << value if value.kind_of? RDFSource
        return self
      end
      super
      if value.kind_of? RDFSource
        resource << value
        value.set_persistence_strategy(ParentStrategy)
        value.persistence_strategy.parent = resource
      end
    end
  end
end
