require 'digest/sha1'
require 'ld/patch'

module RDF::LDP
  ##
  # The base class for all directly usable LDP Resources that *are not*
  # `NonRDFSources`. RDFSources are implemented as a resource with:
  #
  #   - a `#graph` representing the "entire persistent state"
  #   - a `#metagraph` containing internal properties of the RDFSource
  #
  # Repository implementations must be able to reconstruct both `#graph` and
  # `#metagraph` accurately and separately (e.g., by saving them as distinct
  # named graphs).
  #
  # The implementations of `#create` and `#update` in `RDF::LDP::Resource` are
  # overloaded to handle the edits to `#graph` within the same transaction as
  # the base `#metagraph` updates. `#to_response` is overloaded to return an
  # unnamed `RDF::Graph`, to be transformed into an HTTP Body by
  # `Rack::LDP::ContentNegotiation`.
  #
  # @note the contents of `#metagraph`'s are *not* the same as
  #   LDP-server-managed triples. `#metagraph` contains internal properties of
  #   the RDFSource which are necessary for the server's management purposes,
  #   but MAY be absent from (or in conflict with) the representation of its
  #   state in `#graph`.
  #
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
  #   Definition of ldp:RDFSource in the LDP specification
  class RDFSource < Resource
    class << self
      ##
      # @return [RDF::URI] uri with lexical representation
      #   'http://www.w3.org/ns/ldp#RDFSource'
      #
      # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source
      def to_uri
        RDF::Vocab::LDP.RDFSource
      end
    end

    ##
    # @see RDF::LDP::Resource#initialize
    def initialize(subject_uri, data = RDF::Repository.new)
      @subject_uri = subject_uri
      @data = data
      super
      self
    end

    ##
    # @return [RDF::Graph] a graph representing the current persistent state of
    #   the resource.
    def graph
      @graph ||= RDF::Graph.new(graph_name: @subject_uri, data: @data)
    end

    ##
    # Creates the RDFSource, populating its graph from the input given
    #
    # @example
    #   repository = RDF::Repository.new
    #   content = StringIO.new('<http://ex.org/1> <http://ex.org/p> "moomin" .')
    #
    #   ldprs = RDF::LDP::RDFSource.new('http://example.org/moomin', repository)
    #   ldprs.create(content, 'text/turtle')
    #
    # @param [IO, File] input  input (usually from a Rack env's
    #   `rack.input` key) used to determine the Resource's initial state.
    # @param [#to_s] content_type  a MIME content_type used to read the graph.
    #
    # @yield gives an in-progress transaction (changeset) to collect changes to
    #   graph, metagraph and other resources' (e.g. containers) graphs.
    # @yieldparam tx [RDF::Transaction] a transaction targeting `#graph` as the
    #   default graph name
    #
    # @example altering changes before execution with block syntax
    #   content = '<http://ex.org/1> <http://ex.org/p> "moomin" .'
    #
    #   ldprs.create(StringIO.new(content), 'text/turtle') do |tx|
    #     tx.insert([RDF::URI('s'), RDF::URI('p'), 'custom'])
    #     tx.insert([RDF::URI('s'), RDF::URI('p'), 'custom', RDF::URI('g')])
    #   end
    #
    # @example validating changes before execution with block syntax
    #   content = '<http://ex.org/1> <http://ex.org/p> "moomin" .'
    #
    #   ldprs.create(StringIO.new(content), 'text/turtle') do |tx|
    #     raise "cannot delete triples on create!" unless tx.deletes.empty?
    #   end
    #
    # @raise [RDF::LDP::RequestError]
    # @raise [RDF::LDP::UnsupportedMediaType] if no reader can be found for the
    #   graph
    # @raise [RDF::LDP::BadRequest] if the identified reader can't parse the
    #   graph
    # @raise [RDF::LDP::Conflict] if the RDFSource already exists
    #
    # @return [RDF::LDP::Resource] self
    def create(input, content_type, &block)
      super do |transaction|
        transaction.insert(parse_graph(input, content_type))
        yield transaction if block_given?
      end
    end

    ##
    # Updates the resource. Replaces the contents of `graph` with the parsed
    # input.
    #
    # @param [IO, File] input  input (usually from a Rack env's
    #   `rack.input` key) used to determine the Resource's new state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input.
    #
    # @yield gives an in-progress transaction (changeset) to collect changes to
    #   graph, metagraph and other resources' (e.g. containers) graphs.
    # @yieldparam tx [RDF::Transaction] a transaction targeting `#graph` as the
    #   default graph name
    #
    # @example altering changes before execution with block syntax
    #   content = '<http://ex.org/1> <http://ex.org/prop> "moomin" .'
    #
    #   ldprs.update(StringIO.new(content), 'text/turtle') do |tx|
    #     tx.insert([RDF::URI('s'), RDF::URI('p'), 'custom'])
    #     tx.insert([RDF::URI('s'), RDF::URI('p'), 'custom', RDF::URI('g')])
    #   end
    #
    # @raise [RDF::LDP::RequestError]
    # @raise [RDF::LDP::UnsupportedMediaType] if no reader can be found for the
    #   graph
    #
    # @return [RDF::LDP::Resource] self
    def update(input, content_type, &block)
      super do |transaction|
        transaction
          .delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
        transaction.insert parse_graph(input, content_type)
        yield transaction if block_given?
      end
    end

    ##
    # Clears the graph and marks as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy(&block)
      super do |tx|
        tx.delete(RDF::Statement(nil, nil, nil, graph_name: subject_uri))
      end
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      true
    end

    ##
    # Returns the graph representing this resource's state, without the graph
    # context.
    def to_response
      RDF::Graph.new << graph
    end

    private

    ##
    # Process & generate response for PUT requsets.
    #
    # @note patch is currently not transactional.
    #
    # @raise [RDF::LDP::UnsupportedMediaType] when a media type other than
    #   LDPatch is used
    # @raise [RDF::LDP::BadRequest] when an invalid document is given
    def patch(_status, headers, env)
      check_precondition!(env)
      method = patch_types[env['CONTENT_TYPE']]

      raise UnsupportedMediaType unless method

      send(method, env['rack.input'], graph)
      set_last_modified
      [200, update_headers(headers), self]
    end

    ##
    # @return [Hash<String,Symbol>] a hash mapping supported PATCH content types
    #   to the method used to process the PATCH request
    def patch_types
      { 'text/ldpatch'              => :ld_patch,
        'application/sparql-update' => :sparql_update }
    end

    def ld_patch(input, graph)
      LD::Patch.parse(input.read).execute(graph)
    rescue LD::Patch::Error => e
      raise BadRequest, e.message
    end

    def sparql_update(input, graph)
      SPARQL.execute(input.read, graph,
                     update:   true,
                     base_uri: RDF::URI.intern(graph.name))
    rescue SPARQL::MalformedQuery => e
      raise BadRequest, e.message
    end

    ##
    # Process & generate response for PUT requsets.
    def put(_status, headers, env)
      check_precondition!(env)

      if exists?
        update(env['rack.input'], env['CONTENT_TYPE'])
        headers = update_headers(headers)
        [200, headers, self]
      else
        create(env['rack.input'], env['CONTENT_TYPE'])
        [201, update_headers(headers), self]
      end
    end

    ##
    # @param [Hash<String, String>] env  a rack env
    # @raise [RDF::LDP::PreconditionFailed]
    def check_precondition!(env)
      raise(PreconditionFailed, 'Etag invalid') if
        env.key?('HTTP_IF_MATCH') && !match?(env['HTTP_IF_MATCH'])
    end

    ##
    # Finds an {RDF::Reader} appropriate for the given content_type and attempts
    # to parse the graph string.
    #
    # @param [IO, File] input  a (Rack) input stream IO object to parse
    #
    # @param [#to_s] content_type  the content type for the reader
    #
    # @return [RDF::Enumerable] the statements in the resulting graph
    #
    # @raise [RDF::LDP::UnsupportedMediaType] if no appropriate reader is found
    #
    # @see https://www.rubydoc.info/github/rack/rack/file/SPEC#The_Input_Stream
    #   Documentation on input streams in the Rack SPEC
    def parse_graph(input, content_type)
      reader = RDF::Reader.for(content_type: content_type.to_s)
      raise(RDF::LDP::UnsupportedMediaType, content_type) if reader.nil?

      begin
        input.rewind
        RDF::Graph.new(graph_name: subject_uri, data: RDF::Repository.new) <<
          reader.new(input.read, base_uri: subject_uri, validate: true)
      rescue RDF::ReaderError => e
        raise RDF::LDP::BadRequest, e.message
      end
    end
  end
end
