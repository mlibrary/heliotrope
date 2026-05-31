begin
  require 'nokogiri'
rescue LoadError => e
end
require 'rexml/document'

if defined?(::Nokogiri)
  module ::Nokogiri::XML
    ##
    # XML Exclusive Canonicalization (c14n) for Nokogiri.
    #
    # Classes mixin this module to implement canonicalization methods.
    #
    # This implementation acts in two parts, first to canonicalize the Node
    # or NoteSet in the context of its containing document, and second to
    # serialize to a lexical representation.
    #
    # @see # @see   https://www.w3.org/TR/xml-exc-c14n/
    class Node
      ##
      # Canonicalize the Node. Return a new instance of this node
      # which is canonicalized and marked as such
      #
      # @param [Hash{Symbol => Object}] options
      # @option options [Hash{String => String}] :namespaces
      #   Namespaces to apply to node.
      # @option options [#to_s] :language
      #   Language to set on node, unless an xml:lang is already set.
      def c14nxl(options = {})
        @c14nxl = true
        self
      end

      ##
      # Serialize a canonicalized Node or NodeSet to XML
      #
      # Override standard #to_s implementation to output in c14n representation
      # if the Node or NodeSet is marked as having been canonicalized
      def to_s_with_c14nxl
        if instance_variable_defined?(:@c14nxl)
          serialize(:save_with => ::Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS)
        else
          to_s_without_c14nxl
        end
      end

      alias_method :to_s_without_c14nxl, :to_s
      alias_method :to_s, :to_s_with_c14nxl
    end

    class Element
      ##
      # Canonicalize the Element. Return a new instance of this node
      # which is canonicalized and marked as such.
      #
      # Apply namespaces either passed as an option, or that are in scope.
      #
      # @param [Hash{Symbol => Object}] options
      #   From {Nokogiri::XML::Node#c14nxl}
      def c14nxl(options = {})
        options[:namespaces] ||= self.namespace_scopes.compact.inject({}) do |memo, ns|
          memo[ns.prefix] = ns.href.to_s
          memo
        end
        element = self.clone

        # Add in-scope namespace definitions
        options[:namespaces].each do |prefix, href|
          if prefix.to_s.empty?
            element.default_namespace = href unless element.namespace
          else
            element.add_namespace(prefix.to_s, href) unless element.namespaces[prefix.to_s]
          end
        end

        # Add language
        element["xml:lang"] = options[:language].to_s if
          options[:language] &&
          element.attribute_with_ns("lang", "http://www.w3.org/XML/1998/namespace").to_s.empty? &&
          element.attribute("lang").to_s.empty?

        element
      end
    end

    class NodeSet
      ##
      # Canonicalize the NodeSet. Return a new NodeSet marked
      # as being canonical with all child nodes canonicalized.
      #
      # @param [Hash{Symbol => Object}] options
      #   Passed to `Nokogiri::XML::Node#c14nxl`
      def c14nxl(options = {})
        # Create a new NodeSet
        set = self.dup
        set.pop while !set.empty?
        set.instance_variable_set(:@c14nxl, true)

        self.each {|c| set << c.c14nxl(options)}
        set
      end

      ##
      # Serialize a canonicalized Node or NodeSet to XML
      #
      # Override standard #to_s implementation to output in c14n representation
      # if the Node or NodeSet is marked as having been canonicalized
      def to_s_with_c14nxl
        if instance_variable_defined?(:@c14nxl)
          to_a.map {|c| c.serialize(:save_with => ::Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS)}.join("")
        else
          to_s_without_c14nxl
        end
      end

      alias_method :to_s_without_c14nxl, :to_s
      alias_method :to_s, :to_s_with_c14nxl
    end

    class Document
      def doctype
        self.children.first rescue false
      end
    end
  end
end

## REXML C14N
class Array
  ##
  # Canonicalize the NodeSet. Return a new NodeSet marked
  # as being canonical with all child nodes canonicalized.
  #
  # @param [Hash{Symbol => Object}] options
  #   Passed to {Nokogiri::XML::Node#c14nxl}
  def c14nxl(options = {})
    # Create a new NodeSet
    set = []
    set.instance_variable_set(:@c14nxl, true)

    # Unless passed a set of namespaces, figure them out from namespace_scopes
    #options[:namespaces] ||= first.parent.namespace_scopes.compact.inject({}) do |memo, ns|
    #  memo[ns.prefix] = ns.href.to_s
    #  memo
    #end

    self.each {|c| set << (c.respond_to?(:c14nxl) ? c.c14nxl(options) : c)}
    set
  end

  ##
  # Serialize a canonicalized Node or NodeSet to XML
  #
  # Override standard #to_s implementation to output in c14n representation
  # if the Node or NodeSet is marked as having been canonicalized
  def to_s_with_c14nxl
    if instance_variable_defined?(:@c14nxl)
      map {|c| c.to_s}.join("")
    else
      to_s_without_c14nxl
    end
  end

  alias_method :to_s_without_c14nxl, :to_s
  alias_method :to_s, :to_s_with_c14nxl
end

class REXML::Element
  ##
  # Canonicalize the Element. Return a new instance of this node
  # which is canonicalized and marked as such.
  #
  # Apply namespaces either passed as an option, or that are in scope.
  #
  # @param [Hash{Symbol => Object}] options
  #   From `Nokogiri::XML::Node#c14nxl`
  def c14nxl(options = {})
    # Add in-scope namespace definitions, unless supplied
    options[:namespaces] ||= self.namespaces
    element = options[:inplace] ? self : self.dup

    # Add in-scope namespace definitions
    options[:namespaces].each do |prefix, href|
      if prefix.to_s.empty?
        element.add_attribute("xmlns", href) unless element.attribute("xmlns")
      else
        element.add_attribute("xmlns:#{prefix}", href) unless element.attribute("xmlns:#{prefix}")
      end
    end

    # Add language
    element.add_attribute("xml:lang", options[:language].to_s) if
      options[:language] &&
      element.attribute("lang", "http://www.w3.org/XML/1998/namespace").to_s.empty? &&
      element.attribute("lang").to_s.empty?

    # Make sure it formats as open/close tags
    element.text = "" if element.text == nil && element.children.empty?
    
    # Recurse through children to ensure tags are set properly
    element.children.each {|c| c.c14nxl(:inplace => true, :namespaces => {}) if c.is_a?(REXML::Element)}
    element
  end
end