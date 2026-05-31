$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'

##
# Abstract class of ShEx [Extension](http://shex.io/shex-semantics/#semantic-actions) extensions.
#
# Extensions are registered automatically when they are required by subclassing this class.
#
# Implementations may provide an initializer which is called once for a given semantic action. Additionally, `enter` and `exit` methods are invoked when beginning any Triple Expression containing this Semantic Action. The `visit` method is invoked once for each matched triple within that Triple Expression.
#
# @example Test extension
#   class Test < ShEx::Extension("http://shex.io/extensions/Test/")
#
#     # Called to initialize module before evaluating shape
#     def initialize(schema: nil, depth: 0, logger: nil, **options)
#     end
#
#     # Called on entry to containing Triple Expression
#     def enter(code: nil, arcs_in: nil, arcs_out: nil, depth: 0, **options)
#     end
#
#     # Called once for each matched statement
#     def visit(code: nil, matched: nil, depth: 0, **options)
#     end
#
#     # Called on entry to containing Triple Expression
#     def exit(code: nil, matched: [], unmatched: [], depth: 0, **options)
#     end
#
#     # Called after shape completes on success or failure
#     def close(schema: nil, depth: 0, **options)
#     end
#
# Subclasses **must** define at least `visit`.
#
# @see http://shex.io/shex-semantics/#semantic-actions
class ShEx::Extension
  extend ::Enumerable

  class << self
    ##
    # The "name" of this class is a URI used to uniquely identify it.
    # @return [String]
    def name
      @@subclasses.invert[self]
    end

    ##
    # Enumerates known Semantic Action classes.
    #
    # @yield  [klass]
    # @yieldparam [Class] klass
    # @return [Enumerator]
    def each(&block)
      if self.equal?(ShEx::Extension)
        # This is needed since all Semantic Action classes are defined using
        # Ruby's autoloading facility, meaning that `@@subclasses` will be
        # empty until each subclass has been touched or require'd.
        @@subclasses.values.each(&block)
      else
        block.call(self)
      end
    end

    ##
    # Return the SemanticAction associated with a URI.
    #
    # @param [#to_s] name
    # @return [SemanticAction]
    def find(name)
      @@subclasses.fetch(name.to_s, nil)
    end

  private
    @@subclasses = {} # @private
    @@uri        = nil     # @private

    def create(uri) # @private
      @@uri = uri
      self
    end

    def inherited(subclass) # @private
      unless @@uri.nil?
        @@subclasses[@@uri.to_s] = subclass
        @@uri = nil
      end
      super
    end

    ShEx::EXTENSIONS.each { |v| require "shex/extensions/#{v}" }
  end

  ##
  # Initializer for a given instance. Implementations _may_ define this for instance and/or class 
  # @param [ShEx::Algebra::Schema] schema top level of the shape expression
  # @param [RDF::Util::Logger] logger
  # @param [Integer] depth for logging
  # @param [Hash{Symbol => Object}] options from shape initialization
  # @return [self]
  def initialize(schema: nil, logger: nil, depth: 0, **options)
    @logger = logger
    @options = options
    self
  end

  ##
  # Called on entry to containing {ShEx::TripleExpression}
  #
  # @param [String] code
  # @param [Array<RDF::Statement>] arcs_in available statements to be matched
  # @param [Array<RDF::Statement>] arcs_out available statements to be matched
  # @param [ShEx::Algebra::TripleExpression] expression containing this semantic act
  # @param [Integer] depth for logging
  # @param [Hash{Symbol => Object}] options
  #   Other, operand-specific options
  # @return [Boolean] Returning `false` results in {ShEx::NotSatisfied} exception
  def enter(code: nil, arcs_in: nil, arcs_out: nil, expression: nil, depth: 0, **options)
    true
  end

  ##
  # Called after a {ShEx::TripleExpression} has matched zero or more statements
  #
  # @param [String] code
  # @param [RDF::Statement] matched statement
  # @param [Integer] depth for logging
  # @param [ShEx::Algebra::TripleExpression] expression containing this semantic act
  # @param [Hash{Symbol => Object}] options
  #   Other, operand-specific options
  # @return [Boolean] Returning `false` results in {ShEx::NotSatisfied}
  def visit(code: nil, matched: nil, expression: nil, depth: 0, **options)
    raise NotImplementedError
  end

  ##
  # Called on exit from containing {ShEx::TripleExpression}
  #
  # @param [String] code
  # @param [Array<RDF::Statement>] matched statements matched by this expression
  # @param [Array<RDF::Statement>] unmatched statements considered, but not matched by this expression
  # @param [ShEx::Algebra::TripleExpression] expression containing this semantic act
  # @param [Integer] depth for logging
  # @param [Hash{Symbol => Object}] options
  #   Other, operand-specific options
  # @return [self]
  def exit(code: nil, matched: [], unmatched: [], expression: nil, depth: 0, **options)
    self
  end

  # Called after shape completes on success or failure
  # @param [ShEx::Algebra::Schema] schema top level of the shape expression
  # @param [Integer] depth for logging
  # @param [Hash{Symbol => Object}] options
  #   Other, operand-specific options
  # @return [self]
  def close(schema: nil, depth: 0, **options)
    self
  end
end