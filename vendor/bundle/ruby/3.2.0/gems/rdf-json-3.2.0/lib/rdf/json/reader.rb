module RDF::JSON
  ##
  # RDF/JSON parser.
  #
  # @example Loading RDF/JSON parsing support
  #   require 'rdf/json'
  #
  # @example Obtaining an RDF/JSON reader class
  #   RDF::Reader.for(:rj)         #=> RDF::JSON::Reader
  #   RDF::Reader.for("etc/doap.rj")
  #   RDF::Reader.for(:file_name      => "etc/doap.rj")
  #   RDF::Reader.for(:file_extension => "rj")
  #   RDF::Reader.for(:content_type   => "application/rj")
  #
  # @example Parsing RDF statements from an RDF/JSON file
  #   RDF::JSON::Reader.open("etc/doap.rj") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @example Parsing RDF statements from an RDF/JSON string
  #   data = StringIO.new(File.read("etc/doap.rj"))
  #   RDF::JSON::Reader.new(data) do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see http://n2.talis.com/wiki/RDF_JSON_Specification
  class Reader < RDF::Reader
    include RDF::Util::Logger
    format RDF::JSON::Format

    ##
    # The graph constructed when parsing.
    #
    # @return [RDF::Graph]
    attr_reader :graph

    ##
    # Initializes the RDF/JSON reader instance.
    #
    # @param  [IO, File, String]       input
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize`)
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    def initialize(input = $stdin, **options, &block)
      super do
        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # Parses an RDF/JSON subject string into a URI reference or blank node.
    #
    # @param  [String] subject
    # @return [RDF::Resource]
    def parse_subject(subject)
      case subject
        when /^_:/ then parse_node(subject)
        else parse_uri(subject)
      end
    end

    ##
    # Parses an RDF/JSON predicate string into a URI reference.
    #
    # @param  [String] predicate
    # @return [RDF::URI]
    def parse_predicate(predicate)
      # TODO: optional support for CURIE predicates? (issue #1 on GitHub).
      parse_uri(predicate, :intern => true)
    end

    ##
    # Parses an RDF/JSON object string into an RDF value.
    #
    # @param  [Hash{String => Object}] object
    # @return [RDF::Value]
    def parse_object(object)
      log_error("missing 'type' key in #{object.inspect}", exception: RDF::ReaderError) unless object.has_key?('type')
      log_error("missing 'value' key in #{object.inspect}", exception: RDF::ReaderError) unless object.has_key?('value')

      case type = object['type']
        when 'bnode'
          parse_node(object['value'])
        when 'uri'
          parse_uri(object['value'])
        when 'literal'
          literal = RDF::Literal.new(object['value'],
            language: object['lang'],
            datatype: object['datatype'],
            )
          literal.validate!     if validate?
          literal.canonicalize! if canonicalize?
          literal
        else
          log_error("expected 'type' to be 'bnode', 'uri', or 'literal', but got #{type.inspect}", exception: RDF::ReaderError)
      end
    rescue RDF::ReaderError
      nil
    end

    ##
    # Parses an RDF/JSON blank node string into an `RDF::Node` instance.
    #
    # @param  [String] string
    # @return [RDF::Node]
    # @since  0.3.0
    def parse_node(string)
      @nodes ||= {}
      id = string[2..-1] # strips off the initial '_:'
      @nodes[id.to_sym] ||= RDF::Node.new(id)
    end
    alias_method :parse_bnode, :parse_node

    ##
    # Parses an RDF/JSON URI string into an `RDF::URI` instance.
    #
    # @param  [String] string
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean] :intern (false)
    # @return [RDF::URI]
    # @since  0.3.0
    def parse_uri(string, **options)
      uri = RDF::URI.send(intern = intern? && options[:intern] ? :intern : :new, string)
      uri.validate!     if validate?
      uri.canonicalize! if canonicalize? && !intern
      uri
    end

    ##
    # @private
    # @see   RDF::Reader#each_statement
    def each_statement(&block)
      if block_given?
        @input.rewind rescue nil
        begin
          ::JSON.parse(@input.read).each do |subject, predicates|
            subject = parse_subject(subject)
            predicates.each do |predicate, objects|
              predicate = parse_predicate(predicate)
              objects.each do |object|
                object = parse_object(object)
                yield RDF::Statement(subject, predicate, object) if object
              end
            end
          end
        rescue ::JSON::ParserError => e
          log_error(e.message)
        end
        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    end

    ##
    # @private
    # @see   RDF::Reader#each_triple
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end
  end # Reader
end # RDF::JSON
