require 'rdf/xsd'

module RDF::TriX
  ##
  # TriX parser.
  #
  # This class supports [REXML][], [LibXML][] and [Nokogiri][] for XML
  # processing, and will automatically select the most performant
  # implementation (Nokogiri or LibXML) that is available. If need be, you
  # can explicitly override the used implementation by passing in a
  # `:library` option to `Reader.new` or `Reader.open`.
  #
  # [REXML]:    https://www.germane-software.com/software/rexml/
  # [LibXML]:   https://rubygems.org/gems/libxml-ruby/
  # [Nokogiri]: https://nokogiri.org/
  #
  # @example Loading TriX parsing support
  #   require 'rdf/trix'
  #
  # @example Obtaining a TriX reader class
  #   RDF::Reader.for(:trix)         #=> RDF::TriX::Reader
  #   RDF::Reader.for("etc/doap.xml")
  #   RDF::Reader.for(:file_name      => "etc/doap.xml")
  #   RDF::Reader.for(:file_extension => "xml")
  #   RDF::Reader.for(:content_type   => "application/trix")
  #
  # @example Instantiating a Nokogiri-based reader
  #   RDF::TriX::Reader.new(input, :library => :nokogiri)
  #
  # @example Instantiating a LibXML-based reader
  #   RDF::TriX::Reader.new(input, :library => :libxml)
  #
  # @example Instantiating a REXML-based reader
  #   RDF::TriX::Reader.new(input, :library => :rexml)
  #
  # @example Parsing RDF statements from a TriX file
  #   RDF::TriX::Reader.open("etc/doap.xml") do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @example Parsing RDF statements from a TriX string
  #   data = StringIO.new(File.read("etc/doap.xml"))
  #   RDF::TriX::Reader.new(data) do |reader|
  #     reader.each_statement do |statement|
  #       puts statement.inspect
  #     end
  #   end
  #
  # @see https://www.w3.org/2004/03/trix/
  class Reader < RDF::Reader
    format RDF::TriX::Format

    ##
    # Returns the XML implementation module for this reader instance.
    #
    # @return [Module]
    attr_reader :implementation

    ##
    # Returns the Base URI as provided, or found from xml:base
    #
    # @return [RDF::URI]
    attr_reader :base_uri

    ##
    # Initializes the TriX reader instance.
    #
    # @param  [IO, File, String] input
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize`)
    # @option options [Symbol] :library (:nokogiri, :libxml, or :rexml)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    def initialize(input = $stdin, **options, &block)
      super do
        @library = case options[:library]
          when nil
            # Use Nokogiri or LibXML when available, and REXML otherwise:
            begin
              require 'nokogiri'
              :nokogiri
            rescue LoadError => e
              begin
                require 'libxml'
                :libxml
              rescue LoadError => e
                :rexml
              end
            end
          when :nokogiri, :libxml, :rexml
            options[:library]
          else
            raise ArgumentError.new("expected :rexml, :libxml or :nokogiri, but got #{options[:library].inspect}")
        end

        require "rdf/trix/reader/#{@library}"
        @implementation = case @library
          when :nokogiri then Nokogiri
          when :libxml   then LibXML
          when :rexml    then REXML
        end
        self.extend(@implementation)

        begin
          initialize_xml(input, **options)
        rescue
          log_error("Malformed document: #{$!.message}")
        end

        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # @private
    # @see RDF::Reader#each_graph
    def each_graph(&block)
      if block_given?
        base = read_base
        @base_uri = base_uri ? base : base_uri.join(base)
        find_graphs do |graph_element|
          graph_name = read_graph(graph_element)
          graph_name = base_uri.join(graph_name) if
            base_uri && graph_name && graph_name.relative?
          graph = RDF::Graph.new(graph_name: graph_name)
          read_statements(graph_element) { |statement| graph << statement }
          block.call(graph)
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_graph
    end

    ##
    # @private
    # @see RDF::Reader#each_statement
    def each_statement(&block)
      if block_given?
        base = read_base
        @base_uri = base_uri ? base_uri.join(base) : base
        find_graphs do |graph_element|
          read_statements(graph_element, &block)
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_statement
    end

    ##
    # @private
    # @see RDF::Reader#each_triple
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_triple
    end

    ##
    # @private
    # @see RDF::Reader#each_quad
    def each_quad(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_quad)
        end
      end
      enum_quad
    end

    ##
    # Yield each statement from a graph
    #
    # @param [Object] graph_element
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def read_statements(graph_element, &block)
      graph_name = read_graph(graph_element)
      graph_name = base_uri.join(graph_name) if
        base_uri && graph_name && graph_name.relative?
      triple_elements(graph_element).each do |triple_element|
        block.call(read_triple(triple_element, graph_name: graph_name))
      end
    end

    ##
    # Read a <triple>
    # @param  [Hash{String => Object}] element
    # @return [RDF::Statement] statement
    def read_triple(element, graph_name: nil)
      terms = element_elements(element)[0..2].map do |element|
        parse_element(element.name, element, element_content(element))
      end
      RDF::Statement(*terms, graph_name: graph_name)
    end

    ##
    # Returns the RDF value of the given TriX element.
    #
    # @param  [String] name
    # @param  [Hash{String => Object}] element
    # @param  [String] content
    # @return [RDF::Value]
    def parse_element(name, element, content)
      case name.to_sym
        when :id
          RDF::Node.intern(content.strip)
        when :uri
          uri = RDF::URI.new(content.strip) # TODO: interned URIs
          uri = base_uri.join(uri) if base_uri && uri.relative?
          uri.validate!     if validate?
          uri.canonicalize! if canonicalize?
          uri
        when :triple # RDF-star
          log_error "expected 'triple' element" unless @options[:rdfstar]
          read_triple(element)
        when :typedLiteral
          content = element.children.c14nxl(library: @library) if
            element['datatype'] == RDF.XMLLiteral
          literal = RDF::Literal.new(content, :datatype => RDF::URI(element['datatype']))
          literal.validate!     if validate?
          literal.canonicalize! if canonicalize?
          literal
        when :plainLiteral
          literal = case
            when lang = element['xml:lang'] || element['lang']
              RDF::Literal.new(content, :language => lang)
            else
              RDF::Literal.new(content)
          end
          literal.validate!     if validate?
          literal.canonicalize! if canonicalize?
          literal
        else
          log_error "expected element name to be 'id', 'uri', 'triple', 'typedLiteral', or 'plainLiteral', but got #{name.inspect}"
      end
    end
  end # Reader
end # RDF::TriX
