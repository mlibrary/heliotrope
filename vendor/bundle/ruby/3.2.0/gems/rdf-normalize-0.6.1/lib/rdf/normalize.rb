require 'rdf'
require 'digest'

module RDF
  ##
  # **`RDF::Normalize`** is an RDF Graph normalization plugin for RDF.rb.
  #
  # @example Requiring the `RDF::Normalize` module
  #   require 'rdf/normalize'
  #
  # @example Returning an iterator for normalized statements
  #
  #   g = RDF::Graph.load("etc/doap.ttl")
  #   RDF::Normalize.new(g).each_statement do |statement
  #     puts statement.inspect
  #   end
  #
  # @example Returning normalized N-Quads
  #
  #   g = RDF::Graph.load("etc/doap.ttl")
  #   g.dump(:normalize)
  #
  # @example Writing a repository as normalized N-Quads
  #
  #   RDF::Normalize::Writer.open("etc/doap.nq") do |writer|
  #     writer << RDF::Repository.load("etc/doap.ttl")
  #   end
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module Normalize
    require  'rdf/normalize/format'
    autoload :Base,       'rdf/normalize/base'
    autoload :Carroll2001,'rdf/normalize/carroll2001'
    autoload :URGNA2012,  'rdf/normalize/urgna2012'
    autoload :RDFC10,     'rdf/normalize/rdfc10'
    autoload :VERSION,    'rdf/normalize/version'
    autoload :Writer,     'rdf/normalize/writer'

    # Enumerable to normalize
    # @return [RDF::Enumerable]
    attr_accessor :dataset

    ALGORITHMS = {
      carroll2001: :Carroll2001,
      urgna2012:   :URGNA2012,
      rdfc10:   :RDFC10
    }.freeze

    ##
    # Creates a new normalizer instance using either the specified or default normalizer algorithm
    # @param [RDF::Enumerable] enumerable
    # @param [Hash{Symbol => Object}] options
    # @option options [Base] :algorithm (:rdfc10)
    #   One of `:carroll2001`, `:urgna2012`, or `:rdfc10`
    # @option options [Integer] :max_calls
    #   Maximum number of calls allowed for recursive blank node labeling,
    #   as a multiple of the total number of blank nodes in the dataset.
    # @option options [Boolean] :identifier_map
    # @return [RDF::Normalize::Base]
    # @raise [ArgumentError] selected algorithm not defined
    def new(enumerable, **options)
      algorithm = options.fetch(:algorithm, :rdfc10)
      raise ArgumentError, "No algoritm defined for #{algorithm.to_sym}" unless ALGORITHMS.has_key?(algorithm)
      algorithm_class = const_get(ALGORITHMS[algorithm])
      algorithm_class.new(enumerable, **options)
    end
    module_function :new

  end
end
