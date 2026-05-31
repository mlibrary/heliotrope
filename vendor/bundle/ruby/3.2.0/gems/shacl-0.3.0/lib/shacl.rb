require 'shacl/format'
require 'shacl/shapes'
require 'shacl/refinements'
require 'rdf/vocab/shacl'

##
# A SHACL runtime for RDF.rb.
#
# @see https://www.w3.org/TR/shacl/

module SHACL
  autoload :Algebra,    'shacl/algebra'
  autoload :VERSION,    'shacl/version'

  ##
  # Transform the given _Shapes Graph_ into a set of executable shapes.
  #
  # A _Shapes Graph_ may contain an `owl:imports` property referencing additional _Shapes Graphs_, which are resolved until no more imports are found.
  #
  # @param  (see Shapes#from_graph)
  # @option (see Shapes#from_graph)
  # @return (see Shapes#from_graph)
  # @raise  (see Shapes#from_graph)
  def self.get_shapes(shapes_graph, **options)
    Shapes.from_graph(shapes_graph, **options)
  end

  ##
  # Parse a given resource into a _Shapes Graph_.
  #
  # @param  [String, IO, StringIO, #to_s] input
  # @option (see Shapes#from_graph)
  # @return (see Shapes#from_graph)
  # @raise  (see Shapes#from_graph)
  def self.open(input, **options)
    # Create graph backed by repo to allow a graph_name
    graph = RDF::Graph.load(input,
                            graph_name: RDF::URI(input),
                            data: RDF::Repository.new)
    self.get_shapes(graph,
      loaded_graphs: [RDF::URI(input, canonicalize: true)],
      **options)
  end

  ##
  # Retrieve shapes from a sh:shapesGraph reference within queryable
  #
  # @param  (see Shapes#from_queryable)
  # @option (see Shapes#from_queryable)
  # @return (see Shapes#from_queryable)
  # @raise  (see Shapes#from_queryable)
  def self.from_queryable(queryable, **options)
    Shapes.from_queryable(queryable, **options)
  end

  ##
  # The _Shapes Graph_, is established similar to the _Data Graph_, but may be `nil`. If `nil`, the _Data Graph_ may reference a _Shapes Graph_ thorugh an `sh:shapesGraph` property.
  #
  # Additionally, a _Shapes Graph_ may contain an `owl:imports` property referencing additional _Shapes Graphs_, which are resolved until no more imports are found.
  #
  # Load and validate the given SHACL `expression` string against `queriable`.
  #
  # @param  [String, IO, StringIO, #to_s] input
  # @param [RDF::Queryable] queryable
  # @param [Hash{Symbol => Object}] options
  # @options (see Shapes#initialize)
  # @return (see Shapes#execute)
  # @raise (see Shapes#execute)
  def self.execute(input, queryable = nil, **options)
    queryable = queryable || RDF::Graph.new
    shapes = if input
      self.open(input, **options)
    else
      Shapes.from_queryable(queryable)
    end

    shapes.execute(queryable, **options)
  end

  class Error < StandardError
    # The status code associated with this error
    attr_reader :code

    ##
    # Initializes a new error instance.
    #
    # @param  [String, #to_s]          message
    # @param  [Hash{Symbol => Object}] options
    # @option options [Integer]        :code (422)
    def initialize(message, **options)
      @code = options.fetch(:status_code, 422)
      super(message.to_s)
    end
  end

  # Shape expectation not satisfied
  class StructureError < Error; end
end
