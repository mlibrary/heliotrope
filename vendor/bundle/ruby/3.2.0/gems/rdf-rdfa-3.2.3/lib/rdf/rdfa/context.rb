module RDF::RDFa
  ##
  # Context representation existing of a hash of terms, prefixes, a default vocabulary and a URI.
  #
  # Contexts are used for storing RDFa context representations. A representation is created
  # by serializing a context graph (typically also in RDFa, but may be in other representations).
  #
  # The class may be backed by an RDF::Repository, which will be used to retrieve a context graph
  # or to load into, if no such graph exists
  class Context
    include RDF::Util::Logger

    # Prefix mappings defined in this context
    # @!attribute [r] prefixes
    # @return  [Hash{Symbol => RDF::URI}]
    attr_reader :prefixes

    # Term mappings defined in this context
    # @!attribute [r] terms
    # @return [Hash{Symbol => RDF::URI}]
    attr_reader :terms

    # Default URI defined for this vocabulary
    # @!attribute [r] vocabulary
    # @return [RDF::URI]
    attr_reader :vocabulary

    # URI defining this context
    # @!attribute [r] uri
    # @return [RDF::URI]
    attr_reader :uri

    ##
    # Initialize a new context from the given URI.
    #
    # Parses the context and places it in the repository and cache
    #
    # @param [RDF::URI, #to_s] uri URI of context to be represented
    # @yield [context]
    # @yieldparam [RDF::RDFa::Context] context
    # @yieldreturn [void] ignored
    # @return [RDF::RDFa::Context]
    def initialize(uri, **options, &block)
      @uri = RDF::URI.intern(uri)
      @prefixes = options.fetch(:prefixes, {})
      @terms = options.fetch(:terms, {})
      @vocabulary = options[:vocabulary]
      @options = options.dup

      yield(self) if block_given?
      self
    end

    ##
    # @return [RDF::Util::Cache]
    # @private
    def self.cache
      require 'rdf/util/cache' unless defined?(::RDF::Util::Cache)
      @cache ||= begin
        RDF::Util::Cache.new(-1)
      end
    end

    ##
    # Repository used for saving contexts
    # @return [RDF::Repository]
    def self.repository
      @repository ||= RDF::Repository.new(title: "RDFa Contexts")
    end

    ##
    # Set repository used for saving contexts
    # @param [RDF::Repository] repo
    # @return [RDF::Repository]
    def self.repository=(repo)
      unless repo.supports?(:graph_name)
        if respond_to?(:log_fatal)
          log_fatal("Context Repository must support graph_name", exception: ContextError)
        else
          abort("Context Repository must support graph_name")
        end
      end
      @repository = repo
    end

    # Return a context faulting through the cache
    # @return [RDF::RDFa::Context]
    def self.find(uri)
      uri = RDF::URI.intern(uri)

      return cache[uri] unless cache[uri].nil?

      # Two part creation to prevent re-entrancy problems if p1 => p2 and p2 => p1
      # Return something to make the caller happy if we're re-entered
      cache[uri] = Struct.new(:prefixes, :terms, :vocabulary).new({}, {}, nil)
      # Now do the actual load
      cache[uri] = new(uri) do |context|
        log_debug("process_context: retrieve context <#{uri}>") if respond_to?(:log_debug)
        Context.load(uri)
        context.parse(repository.query({graph_name: uri}))
      end
    rescue Exception => e
      if respond_to?(:log_fatal)
        log_error("Context #{uri}: #{e.message}")
      else
        abort("Context #{uri}: #{e.message}")
      end
    end

    # Load context into repository
    def self.load(uri)
      uri = RDF::URI.intern(uri)
      repository.load(uri.to_s, base_uri: uri, graph_name: uri) unless repository.has_graph?(uri)
    end

    # @return [RDF::Repository]
    def repository
      Context.repository
    end

    ##
    # Defines the given named URI prefix for this context.
    #
    # @example Defining a URI prefix
    #   context.prefix :dc, RDF::URI('http://purl.org/dc/terms/')
    #
    # @example Returning a URI prefix
    #   context.prefix(:dc)    #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @param  [Symbol, #to_s]   name
    # @param  [RDF::URI, #to_s] uri
    # @return [RDF::URI]
    def prefix(name, uri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      uri.nil? ? prefixes[name] : prefixes[name] = uri
    end

    ##
    # Defines the given named URI term for this context.
    #
    # @example Defining a URI term
    #   context.term :title, RDF::URI('http://purl.org/dc/terms/title')
    #
    # @example Returning a URI context
    #   context.term(:title)    #=> RDF::URI('http://purl.org/dc/terms/TITLE')
    #
    # @param  [Symbol, #to_s]   name
    # @param  [RDF::URI, #to_s] uri
    # @return [RDF::URI]
    def term(name, uri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      uri.nil? ? terms[name] : terms[name] = uri
    end

    ##
    # Extract vocabulary, prefix mappings and terms from a enumerable object into an instance
    #
    # @param [RDF::Enumerable, Enumerator] enumerable
    # @return [void] ignored
    def parse(enumerable)
      log_debug("process_context: parse context <#{uri}>") if respond_to?(:log_debug)
      resource_info = {}
      enumerable.each do |statement|
        res = resource_info[statement.subject] ||= {}
        next unless statement.object.is_a?(RDF::Literal)
        log_debug("process_context: statement=#{statement.inspect}") if respond_to?(:log_debug)
        %w(uri term prefix vocabulary).each do |term|
          res[term] ||= statement.object.value if statement.predicate == RDF::RDFA[term]
        end
      end

      resource_info.values.each do |res|
        # If one of the objects is not a Literal or if there are additional rdfa:uri or rdfa:term
        # predicates sharing the same subject, no mapping is created.
        uri = res["uri"]
        term = res["term"]
        prefix = res["prefix"]
        vocab = res["vocabulary"]
        log_debug("process_context: uri=#{uri.inspect}, term=#{term.inspect}, prefix=#{prefix.inspect}, vocabulary=#{vocab.inspect}") if respond_to?(:log_debug)

        @vocabulary = vocab if vocab

        # For every extracted triple that is the common subject of an rdfa:prefix and an rdfa:uri
        # predicate, create a mapping from the object literal of the rdfa:prefix predicate to the
        # object literal of the rdfa:uri predicate. Add or update this mapping in the local list of
        # URI mappings after transforming the 'prefix' component to lower-case.
        # For every extracted
        prefix(prefix.downcase, uri) if uri && prefix && prefix != "_"

        # triple that is the common subject of an rdfa:term and an rdfa:uri predicate, create a
        # mapping from the object literal of the rdfa:term predicate to the object literal of the
        # rdfa:uri predicate. Add or update this mapping in the local term mappings.
        term(term, uri) if term && uri
      end
    end
  end

  ##
  # The base class for RDF context errors.
  class ContextError < IOError; end
end

# Load cooked contexts
Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'context', '*')).each {|f| load f}
