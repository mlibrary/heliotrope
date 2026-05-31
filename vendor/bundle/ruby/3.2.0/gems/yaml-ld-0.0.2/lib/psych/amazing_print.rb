# frozen_string_literal: true

# Amazing Print extensions for Psych
#------------------------------------------------------------------------------
module AmazingPrint
  module Psych
    def self.included(base)
      base.send :alias_method, :cast_without_psych, :cast
      base.send :alias_method, :cast, :cast_with_psych
    end

    # Add Psych Node names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_psych(object, type)
      cast = cast_without_psych(object, type)
      if (defined?(::Psych::Nodes::Node) && object.is_a?(::Psych::Nodes::Node))
        cast = :psych_node
      end
      cast
    end

STYLES = %w(ANY BLOCK FLOW)    #------------------------------------------------------------------------------
    def awesome_psych_node(object)
      contents = []
      contents << colorize(object.class.name.split('::').last, :class)
      contents << colorize("!<#{object.tag}>", :args) if object.tag
      contents << colorize("&#{object.anchor}", :args) if object.respond_to?(:anchor) && object.anchor
      contents << colorize("(implicit)", :args) if object.respond_to?(:implicit) && object.implicit
      contents << colorize("(implicit end)", :args) if object.respond_to?(:implicit_end) && object.implicit_end
      case object
      when ::Psych::Nodes::Stream
        contents << awesome_array(object.children)
      when ::Psych::Nodes::Document
        contents << colorize('%TAG(' + object.tag_directives.flatten.join(' ') + ')', :args) unless Array(object.tag_directives).empty?
        contents << colorize("version #{object.version.join('.')}", :args) if object.version
        contents << awesome_array(object.children)
      when ::Psych::Nodes::Sequence
        style = %w(ANY BLOCK FLOW)[object.style.to_i]
        contents << awesome_array(object.children)
      when ::Psych::Nodes::Mapping
        style = %w(ANY BLOCK FLOW)[object.style.to_i]
        contents << colorize(style, :args) if object.style
        contents << awesome_hash(object.children.each_slice(2).to_h)
      when ::Psych::Nodes::Scalar
        style = %w(ANY PLAIN SINGLE_QUOTED DOUBLE_QUOTED LITERAL FOLDED)[object.style.to_i]
        contents << colorize(style, :args) if object.style
        contents << colorize("(plain)", :args) if object.plain
        contents << colorize("(quoted)", :args) if object.quoted
        contents << awesome_simple(object.value.inspect, :variable)
      when ::Psych::Nodes::Alias
        # No children
      else
        "Unknown node type: #{object.inspect}"
      end

      contents.join(' ')
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::Psych