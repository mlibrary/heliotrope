require               'rdf'
require               'sxp'
require               'shex/format'

##
# A ShEx runtime for RDF.rb.
#
# @see https://shex.io/shex-semantics/#shexc
module ShEx
  autoload :Algebra,    'shex/algebra'
  autoload :Meta,       'shex/meta'
  autoload :Parser,     'shex/parser'
  autoload :Extension,  'shex/extensions/extension'
  autoload :Terminals,  'shex/terminals'
  autoload :VERSION,    'shex/version'

  # Location of the ShEx JSON-LD context
  CONTEXT = "http://www.w3.org/ns/shex.jsonld"

  # Extensions defined in this gem
  EXTENSIONS = %w{test}

  ##
  # Parse the given ShEx `query` string.
  #
  # @example parsing a ShExC schema
  #   schema = ShEx.parse(%(
  #     PREFIX ex: <http://schema.example/> ex:IssueShape {ex:state IRI}
  #   ).parse
  #
  # @param  [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param  ['shexc', 'shexj', 'sxp']  format ('shexc')
  # @param  [Hash{Symbol => Object}] options
  # @option (see ShEx::Parser#initialize)
  # @return (see ShEx::Parser#parse)
  # @raise  (see ShEx::Parser#parse)
  def self.parse(expression, format: 'shexc', **options)
    case format.to_s
    when 'shexc' then Parser.new(expression, **options).parse
    when 'shexj'
      expression = expression.read if expression.respond_to?(:read)
      Algebra.from_shexj(JSON.parse(expression), **options)
    when 'sxp'
      expression = expression.read if expression.respond_to?(:read)
      Algebra.from_sxp(expression, **options)
    else raise "Unknown expression format: #{format.inspect}"
    end
  end

  ##
  # Parses input from the given file name or URL.
  #
  # @example parsing a ShExC schema
  #   schema = ShEx.parse('foo.shex').parse
  #
  # @param  [String, #to_s] filename
  # @param  (see parse)
  # @option (see ShEx::Parser#initialize)
  # @return (see ShEx::Parser#parse)
  # @raise  (see ShEx::Parser#parse)
  def self.open(filename, format: 'shexc', **options, &block)
    RDF::Util::File.open_file(filename, **options) do |file|
      self.parse(file, format: format, **options)
    end
  end

  ##
  # Parse and validate the given ShEx `expression` string against `queriable`.
  #
  # @example executing a ShExC schema
  #   graph = RDF::Graph.load("etc/doap.ttl")
  #   ShEx.execute('etc/doap.shex', graph, "https://rubygems.org/gems/shex", "")
  #
  # @param [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param (see ShEx::Algebra::Schema#execute)
  # @return (see ShEx::Algebra::Schema#execute)
  # @raise (see ShEx::Algebra::Schema#execute)
  def self.execute(expression, queryable, map, format: 'shexc', **options)
    shex = self.parse(expression, format: format, **options)
    queryable = queryable || RDF::Graph.new

    shex.execute(queryable, map, **options)
  end

  ##
  # Parse and validate the given ShEx `expression` string against `queriable`.
  #
  # @example executing a ShExC schema
  #   graph = RDF::Graph.load("etc/doap.ttl")
  #   ShEx.execute('etc/doap.shex', graph, "https://rubygems.org/gems/shex", "")
  #
  # @param [IO, StringIO, String, #to_s]  expression (ShExC or ShExJ)
  # @param (see ShEx::Algebra::Schema#satisfies?)
  # @return (see ShEx::Algebra::Schema#satisfies?)
  # @raise (see ShEx::Algebra::Schema#satisfies?)
  def self.satisfies?(expression, queryable, map, format: 'shexc', **options)
    shex = self.parse(expression, format: format, **options)
    queryable = queryable || RDF::Graph.new

    shex.satisfies?(queryable, map, **options)
  end

  ##
  # Alias for `ShEx::Extension.create`.
  #
  # @param (see ShEx::Extension#create)
  # @return [Class]
  def self.Extension(uri)
    Extension.send(:create, uri)
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


  # Shape expectation not satisfied
  class StructureError < Error; end

  # Shape expectation not satisfied
  class NotSatisfied < Error
    ##
    # The expression which was not satified
    # @return [ShEx::Algebra::ShapeExpression]
    attr_reader :expression

    ##
    # Initializes a new parser error instance.
    #
    # @param  [String, #to_s]                   message
    # @param  [ShEx::Algebra::ShapeExpression]  expression
    def initialize(message, expression: self)
      @expression = expression
      super(message.to_s)
    end

    def inspect
      super + (expression ? SXP::Generator.string(expression.to_sxp_bin) : '')
    end
  end

  # TripleExpression did not match
  class NotMatched < ShEx::Error
    ##
    # The expression which was not satified
    # @return [ShEx::Algebra::TripleExpression]
    attr_reader :expression

    ##
    # Initializes a new parser error instance.
    #
    # @param  [String, #to_s]                   message
    # @param  [ShEx::Algebra::TripleExpression] expression
    def initialize(message, expression: self)
      @expression = expression
      super(message.to_s)
    end

    def inspect
      super + (expression ? SXP::Generator.string(expression.to_sxp_bin) : '')
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
    # ParseError includes `token` and `lineno` associated with the expression.
    #
    # @param  [String, #to_s]          message
    # @param [String]                  token  (nil)
    # @param [Integer]                 lineno (nil)
    def initialize(message, token: nil, lineno: nil)
      @token      = token
      @lineno     = lineno || (@token.lineno if @token.respond_to?(:lineno))
      super(message.to_s)
    end
  end
end
