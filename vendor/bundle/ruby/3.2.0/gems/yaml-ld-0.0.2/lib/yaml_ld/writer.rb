# -*- encoding: utf-8 -*-
require 'json/ld/writer'

module YAML_LD
  ##
  # A YAML-LD serializer in Ruby.
  class Writer < JSON::LD::Writer
    ##
    # Initializes the YAML-LD writer instance.
    #
    # @param  [IO, File] output
    #   the output stream
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding to use on the output stream (Ruby 1.9+)
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize literals when serializing
    # @option options [Hash]     :prefixes     ({})
    #   the prefix mappings to use (not supported by all writers)
    # @option options [Boolean]  :standard_prefixes   (false)
    #   Add standard prefixes to @prefixes, if necessary.
    # @option options [IO, Array, Hash, String, Context]     :context     ({})
    #   context to use when serializing. Constructed context for native serialization.
    # @option options [IO, Array, Hash, String, Context]     :frame     ({})
    #   frame to use when serializing.
    # @option options [Boolean]  :unique_bnodes   (false)
    #   Use unique bnode identifiers, defaults to using the identifier which the node was originall initialized with (if any).
    # @option options [Proc] serializer (YAML_LD::API.serializer)
    #   A Serializer method used for generating the YAML serialization of the result.
    # @option options [Boolean] :stream (false)
    #   Do not attempt to optimize graph presentation, suitable for streaming large graphs.
    # @yield  [writer] `self`
    # @yieldparam  [RDF::Writer] writer
    # @yieldreturn [void]
    # @yield  [writer]
    # @yieldparam [RDF::Writer] writer
    def initialize(output = $stdout, **options, &block)
      super(output, **options.merge(serializer: YAML_LD::API.method(:serializer)), &block)
    end
  end
end