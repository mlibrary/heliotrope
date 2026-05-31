$:.unshift(File.expand_path("../..", __FILE__))
require 'rdf'
require 'sparql'
require 'sparql/algebra'
require 'sxp'

module LD
  # **`LD::Patch`** is a Linked Data Patch extension for RDF.rb.
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Patch
    require 'ld/patch/format'
    autoload :Algebra,      'ld/patch/algebra'
    autoload :Meta,         'ld/patch/meta'
    autoload :Parser,       'ld/patch/parser'
    autoload :Terminals,    'ld/patch/terminals'
    autoload :VERSION,      'ld/patch/version'

    ##
    # Parse the given LD Patch `input` string.
    #
    # @example
    #   query = LD::Patch.parse("Add { <http://example.org/s2> <http://example.org/p2> <http://example.org/o2> } .")
    #
    # @param  [IO, StringIO, String, #to_s]  input
    # @param  [Hash{Symbol => Object}] options
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs
    # @option (see LD::Patch::Parser#initialize)
    # @return [SPARQL::Algebra::Operator] The executable parsed Patch
    def self.parse(input, **options)
      LD::Patch::Parser.new(input, **options).parse
    end

    class Error < StandardError
      # The status code associated with this error
      attr_reader :code

      ##
      # Initializes a new patch error instance.
      #
      # @param  [String, #to_s]          message
      # @param  [Hash{Symbol => Object}] options
      # @option options [Integer]        :code (422)
      def initialize(message, **options)
        @code = options.fetch(:status_code, 422)
        super(message.to_s)
      end
    end

    # Indicates bad syntax found in LD Patch document
    class ParseError < Error
      ##
      # The invalid token which triggered the error.
      #
      # @return [String]
      attr_reader :token

      ##
      # The line number where the error occurred.
      #
      # @return [Integer]
      attr_reader :lineno

      ##
      # Initializes a new parser error instance.
      #
      # @param  [String, #to_s]          message
      # @param  [Hash{Symbol => Object}] options
      # @option options [String]         :token  (nil)
      # @option options [Integer]        :lineno (nil)
      # @option options [Integer]        :code (400)
      def initialize(message, **options)
        @token      = options[:token]
        @lineno     = options[:lineno] || (@token.lineno if @token.respond_to?(:lineno))
        super(message.to_s, code: options.fetch(:code, 400))
      end
    end
  end
end


