require 'link_header'

module RDF::LDP
  ##
  # The base class for all LDP Resources.
  #
  # The internal state of a Resource is specific to a given persistent datastore
  # (an `RDF::Repository` passed to the initilazer) and is managed through an
  # internal graph (`#metagraph`). A Resource has:
  #
  #   - a `#subject_uri` identifying the Resource.
  #   - a `#metagraph` containing server-internal properties of the Resource.
  #
  # Resources also define a basic set of CRUD operations, identity and current
  # state, and a `#to_response`/`#each` method used by Rack & `Rack::LDP` to
  # generate an appropriate HTTP response body.
  #
  # `#metagraph' holds internal properites used by the server. It is distinct
  # from, and may conflict with, other RDF and non-RDF information about the
  # resource (e.g. representations suitable for a response body). Metagraph
  # contains a canonical `rdf:type` statement, which specifies the resource's
  # interaction model and a (dcterms:modified) last-modified date. If the
  # resource is deleted, a (prov:invalidatedAt) flag in metagraph indicates
  # this.
  #
  # The contents of `#metagraph` should not be confused with LDP
  # server-managed-triples, Those triples are included in the state of the
  # resource as represented by the response body. `#metagraph` is invisible to
  # the client except where a subclass mirrors its contents in the body.
  #
  # @example creating a new Resource
  #   repository = RDF::Repository.new
  #   resource = RDF::LDP::Resource.new('http://example.org/moomin', repository)
  #   resource.exists? # => false
  #
  #   resource.create(StringIO.new(''), 'text/plain')
  #
  #   resource.exists? # => true
  #   resource.metagraph.dump :ttl
  #   # => "<http://example.org/moomin> a <http://www.w3.org/ns/ldp#Resource>;
  #   #       <http://purl.org/dc/terms/modified>
  #   #         "2015-10-25T14:24:56-07:00"^^xsd:dateTime ."
  #
  # @example updating a Resource updates the `#last_modified` date
  #   resource.last_modified
  #   # => #<DateTime: 2015-10-25T14:32:01-07:00...>
  #   resource.update('blah', 'text/plain')
  #   resource.last_modified
  #   # => #<DateTime: 2015-10-25T14:32:04-07:00...>
  #
  # @example destroying a Resource
  #   resource.exists? # => true
  #   resource.destroyed? # => false
  #
  #   resource.destroy
  #
  #   resource.exists? # => true
  #   resource.destroyed? # => true
  #
  # Rack (via `RDF::LDP::Rack`) uses the `#request` method to dispatch requests
  # and interpret responses. Disallowed HTTP methods result in
  # `RDF::LDP::MethodNotAllowed`. Individual Resources populate `Link`, `Allow`,
  # `ETag`, `Last-Modified`, and `Accept-*` headers as required by LDP. All
  # subclasses (MUST) return `self` as the Body, and respond to `#each`/
  # `#respond_to` with the intended body.
  #
  # @example using HTTP request methods to get a Rack response
  #   resource.request(:get, 200, {}, {})
  #   # => [200,
  #         {"Link"=>"<http://www.w3.org/ns/ldp#Resource>;rel=\"type\"",
  #          "Allow"=>"GET, DELETE, OPTIONS, HEAD",
  #          "Accept-Post"=>"",
  #          "Accept-Patch"=>"",
  #          "ETag"=>"W/\"2015-10-25T21:39:13.111500405+00:00\"",
  #          "Last-Modified"=>"Sun, 25 Oct 2015 21:39:13 GMT"},
  #         #<RDF::LDP::Resource:0x00564f4a646028
  #           @data=#<RDF::Repository:0x2b27a5391708()>,
  #           @exists=true,
  #           @metagraph=#<RDF::Graph:0xea7(http://example.org/moomin#meta)>,
  #           @subject_uri=#<RDF::URI:0xea8 URI:http://example.org/moomin>>]
  #
  #   resource.request(:put, 200, {}, {}) # RDF::LDP::MethodNotAllowed: put
  #
  # @see https://www.w3.org/TR/ldp/ Linked Data platform Specification
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource Definition
  #   of 'Resource' in LDP
  class Resource
    CONTAINS_URI       = RDF::Vocab::LDP.contains.freeze
    INVALIDATED_AT_URI = RDF::Vocab::PROV.invalidatedAtTime.freeze
    MODIFIED_URI       = RDF::Vocab::DC.modified.freeze

    # @!attribute [r] subject_uri
    #   an rdf term identifying the `Resource`
    attr_reader :subject_uri

    # @!attribute [rw] metagraph
    #   a graph representing the server-internal state of the resource
    attr_accessor :metagraph

    class << self
      ##
      # @return [RDF::URI] uri with lexical representation
      #   'http://www.w3.org/ns/ldp#Resource'
      #
      # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-resource
      def to_uri
        RDF::Vocab::LDP.Resource
      end

      ##
      # Creates an unique id (URI Slug) for a resource.
      #
      # @note the current implementation uses `SecureRandom#uuid`.
      #
      # @return [String] a unique ID
      def gen_id
        SecureRandom.uuid
      end

      ##
      # Finds an existing resource and
      #
      # @param [RDF::URI] uri  the URI for the resource to be found
      # @param [RDF::Repository] data  a repostiory instance in which to find
      #   the resource.
      #
      # @raise [RDF::LDP::NotFound] when the resource doesn't exist
      #
      # @return [RDF::LDP::Resource] a resource instance matching the given URI;
      #   usually of a subclass
      #   from the interaction models.
      def find(uri, data)
        graph = RDF::Graph.new(graph_name: metagraph_name(uri), data: data)
        raise NotFound if graph.empty?

        klass = graph.query([uri, RDF.type, :o]).find do |rdf_class|
          candidate = InteractionModel.for(rdf_class.object)
          break candidate unless candidate.nil?
        end
        klass ||= RDFSource

        klass.new(uri, data)
      end

      ##
      # Retrieves the correct interaction model from the Link headers.
      #
      # Headers are handled intelligently, e.g. if a client sends a request with
      # Resource, RDFSource, and BasicContainer headers, the server gives a
      # BasicContainer. An error is thrown if the headers contain conflicting
      # types (i.e. NonRDFSource and another Resource class).
      #
      # @param [String] link_header  a string containing Link headers from an
      #   HTTP request (Rack env)
      #
      # @return [Class] a subclass of {RDF::LDP::Resource} matching the
      #   requested interaction model;
      def interaction_model(link_header)
        models =
          LinkHeader.parse(link_header)
                    .links.select { |link| link['rel'].casecmp 'type' }
                    .map { |link| RDF::URI.intern(link.href) }

        return InteractionModel.default if models.empty?

        raise NotAcceptable unless InteractionModel.compatible?(models)

        InteractionModel.find(models)
      end

      ##
      # Build a graph name URI for the uri passed in
      #
      # @param uri [RDF::URI]
      def metagraph_name(uri)
        uri + '#meta'
      end
    end

    ##
    # @param [RDF::URI, #to_s] subject_uri  the uri that identifies the Resource
    # @param [RDF::Repository] data  the repository where the resource's RDF
    #   data (i.e. `metagraph`) is stored; defaults to an in-memory
    #   RDF::Repository specific to this Resource.
    #
    # @yield [RDF::Resource] Gives itself to the block
    #
    # @example
    #   RDF::Resource.new('http://example.org/moomin')
    #
    # @example with a block
    #   RDF::Resource.new('http://example.org/moomin') do |resource|
    #     resource.metagraph << RDF::Statement(...)
    #   end
    #
    def initialize(subject_uri, data = RDF::Repository.new)
      @subject_uri = RDF::URI.intern(subject_uri)
      @data = data
      @metagraph = RDF::Graph.new(graph_name: metagraph_name, data: data)
      yield self if block_given?
    end

    ##
    # @abstract creates the resource
    #
    # @param [IO, File] _input  input (usually from a Rack env's
    #   `rack.input` key) used to determine the Resource's initial state.
    # @param [#to_s] _content_type  a MIME content_type used to interpret the
    #   input. This MAY be used as a content type for the created Resource
    #   (especially for `LDP::NonRDFSource`s).
    #
    # @yield gives a transaction (changeset) to collect changes to graph,
    #  metagraph and other resources' (e.g. containers) graphs
    # @yieldparam tx [RDF::Transaction]
    # @return [RDF::LDP::Resource] self
    #
    # @raise [RDF::LDP::RequestError] when creation fails. May raise various
    #   subclasses for the appropriate response codes.
    # @raise [RDF::LDP::Conflict] when the resource exists
    def create(_input, _content_type)
      raise Conflict if exists?

      @data.transaction(mutable: true) do |transaction|
        set_interaction_model(transaction)
        yield transaction if block_given?
        set_last_modified(transaction)
      end

      self
    end

    ##
    # @abstract update the resource
    #
    # @param [IO, File, #to_s] input  input (usually from a Rack env's
    #   `rack.input` key) used to determine the Resource's new state.
    # @param [#to_s] content_type  a MIME content_type used to interpret the
    #   input.
    #
    # @yield gives a transaction (changeset) to collect changes to graph,
    #  metagraph and other resources' (e.g. containers) graphs
    # @yieldparam tx [RDF::Transaction]
    # @return [RDF::LDP::Resource] self
    #
    # @raise [RDF::LDP::RequestError] when update fails. May raise various
    #   subclasses for the appropriate response codes.
    def update(input, content_type, &block)
      return create(input, content_type, &block) unless exists?

      @data.transaction(mutable: true) do |transaction|
        yield transaction if block_given?
        set_last_modified(transaction)
      end

      self
    end

    ##
    # Mark the resource as destroyed.
    #
    # This adds a statment to the metagraph expressing that the resource has
    # been deleted
    #
    # @yield gives a transaction (changeset) to collect changes to graph,
    #  metagraph and other resources' (e.g. containers) graphs
    # @yieldparam tx [RDF::Transaction]
    # @return [RDF::LDP::Resource] self
    #
    # @todo Use of owl:Nothing is probably problematic. Define an internal
    # namespace and class represeting deletion status as a stateful property.
    def destroy
      @data.transaction(mutable: true) do |transaction|
        containers.each { |c| c.remove(self, transaction) if c.container? }
        transaction.insert RDF::Statement(subject_uri,
                                          INVALIDATED_AT_URI,
                                          DateTime.now,
                                          graph_name: metagraph_name)
        yield transaction if block_given?
      end
      self
    end

    ##
    # Gives the status of the resource's existance.
    #
    # @note destroyed resources continue to exist in the sense represeted by
    #   this method.
    #
    # @return [Boolean] true if the resource exists within the repository
    def exists?
      @data.has_graph? metagraph.graph_name
    end

    ##
    # @return [Boolean] true if resource has been destroyed
    def destroyed?
      times = @metagraph.query([subject_uri, INVALIDATED_AT_URI, nil])
      !times.empty?
    end

    ##
    # Returns an Etag. This may be a strong or a weak ETag.
    #
    # @return [String] an HTTP Etag
    #
    # @note these etags are weak, but we allow clients to use them in
    #   `If-Match` headers, and use weak comparison. This is in conflict with
    #   https://tools.ietf.org/html/rfc7232#section-3.1. See:
    #   https://github.com/ruby-rdf/rdf-ldp/issues/68
    #
    # @see https://www.w3.org/TR/ldp#h-ldpr-gen-etags  LDP ETag clause for GET
    # @see https://www.w3.org/TR/ldp#h-ldpr-put-precond  LDP ETag clause for PUT
    # @see https://tools.ietf.org/html/rfc7232#section-2.1
    #   Weak vs. strong validators
    def etag
      return nil unless exists?
      "W/\"#{last_modified.new_offset(0).iso8601(9)}\""
    end

    ##
    # @return [DateTime] the time this resource was last modified; `nil` if the
    #   resource doesn't exist and has no modified date
    # @raise [RDF::LDP::RequestError] when the resource exists but is missing a
    #   `last_modified'
    #
    # @todo handle cases where there is more than one RDF::DC.modified.
    #    check for the most recent date
    def last_modified
      results = @metagraph.query([subject_uri, RDF::Vocab::DC.modified, :time])

      if results.empty?
        return nil unless exists?
        raise(RequestError, "Missing dc:modified date for #{subject_uri}")
      end

      results.first.object.object
    end

    ##
    # @param [String] tag  a tag to compare to `#etag`
    # @return [Boolean] whether the given tag matches `#etag`
    def match?(tag)
      tag == etag
    end

    ##
    # @return [RDF::URI] the subject URI for this resource
    def to_uri
      subject_uri
    end

    ##
    # @return [Array<Symbol>] a list of HTTP methods allowed by this resource.
    def allowed_methods
      [:GET, :POST, :PUT, :DELETE, :PATCH, :OPTIONS, :HEAD].select do |m|
        respond_to?(m.downcase, true)
      end
    end

    ##
    # @return [Boolean] whether this is an ldp:Resource
    def ldp_resource?
      true
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      false
    end

    ##
    # @return [Boolean] whether this is an ldp:RDFSource
    def rdf_source?
      false
    end

    ##
    # @return [Array<RDF::LDP::Resource>] the container for this resource
    def containers
      @data.query([:s, CONTAINS_URI, subject_uri]).map do |st|
        RDF::LDP::Resource.find(st.subject, @data)
      end
    end

    ##
    # Runs the request and returns the object's desired HTTP response body,
    # conforming to the Rack interfare.
    #
    # @see https://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Body
    #   Rack body documentation
    def to_response
      []
    end
    alias each to_response

    ##
    # Build the response for the HTTP `method` given.
    #
    # The method passed in is symbolized, downcased, and sent to `self` with the
    # other three parameters.
    #
    # Request methods are expected to return an Array appropriate for a Rack
    # response; to return this object (e.g. for a sucessful GET) the response
    # may be `[status, headers, self]`.
    #
    # If the method given is unimplemented, we understand it to require an HTTP
    # 405 response, and throw the appropriate error.
    #
    # @param [#to_sym] method  the HTTP request method of the response; this
    #   message will be downcased and sent to the object.
    # @param [Fixnum] status  an HTTP response code; this status should be sent
    #   back to the caller or altered, as appropriate.
    # @param [Hash<String, String>] headers  a hash mapping HTTP headers
    #   built for the response to their contents; these headers should be sent
    #   back to the caller or altered, as appropriate.
    # @param [Hash] env  the Rack env for the request
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response
    #   array.
    def request(method, status, headers, env)
      raise Gone if destroyed?
      begin
        send(method.to_sym.downcase, status, headers, env)
      rescue NotImplementedError
        raise MethodNotAllowed, method
      end
    end

    private

    ##
    # Generate response for GET requests. Returns existing status and headers,
    # with `self` as the body.
    def get(status, headers, _env)
      [status, update_headers(headers), self]
    end

    ##
    # Generate response for HEAD requsets. Adds appropriate headers and returns
    # an empty body.
    def head(status, headers, _env)
      [status, update_headers(headers), []]
    end

    ##
    # Generate response for OPTIONS requsets. Adds appropriate headers and
    # returns an empty body.
    def options(status, headers, _env)
      [status, update_headers(headers), []]
    end

    ##
    # Process & generate response for DELETE requests.
    def delete(_status, headers, _env)
      destroy
      headers.delete('Content-Type')
      [204, headers, []]
    end

    ##
    # @abstract implement in subclasses as needed to support HTTP PATCH
    def patch(*)
      raise NotImplementedError
    end

    ##
    # @abstract implement in subclasses as needed to support HTTP POST
    def post(*)
      raise NotImplementedError
    end

    ##
    # @abstract implement in subclasses as needed to support HTTP PUT
    def put(*)
      raise NotImplementedError
    end

    ##
    # @abstract HTTP TRACE is not expected to be supported
    def trace(*)
      raise NotImplementedError
    end

    ##
    # @abstract HTTP CONNECT is not expected to be supported
    def connect(*)
      raise NotImplementedError
    end

    ##
    # @return [RDF::URI] the name for this resource's metagraph
    def metagraph_name
      self.class.metagraph_name(subject_uri)
    end

    ##
    # @param [Hash<String, String>] headers
    # @return [Hash<String, String>] the updated headers
    def update_headers(headers)
      headers['Link'] =
        ([headers['Link']] + link_headers).compact.join(',')

      headers['Allow'] = allowed_methods.join(', ')
      headers['Accept-Post'] = accept_post   if respond_to?(:post, true)
      headers['Accept-Patch'] = accept_patch if respond_to?(:patch, true)

      tag = etag
      headers['ETag'] ||= tag if tag

      modified = last_modified
      headers['Last-Modified'] ||= modified.httpdate if modified

      headers
    end

    ##
    # @return [String] the Accept-Post headers
    def accept_post
      RDF::Reader.map(&:format).compact.map(&:content_type).flatten.join(', ')
    end

    ##
    # @return [String] the Accept-Patch headers
    def accept_patch
      respond_to?(:patch_types, true) ? patch_types.keys.join(',') : ''
    end

    ##
    # @return [Array<String>] an array of link headers to add to the
    #   existing ones
    #
    # @see https://www.w3.org/TR/ldp/#h-ldpr-gen-linktypehdr
    # @see https://www.w3.org/TR/ldp/#h-ldprs-are-ldpr
    # @see https://www.w3.org/TR/ldp/#h-ldpnr-type
    # @see https://www.w3.org/TR/ldp/#h-ldpc-linktypehdr
    def link_headers
      return [] unless is_a? RDF::LDP::Resource
      headers = [link_type_header(RDF::LDP::Resource.to_uri)]
      headers << link_type_header(RDF::LDP::RDFSource.to_uri) if rdf_source?
      headers << link_type_header(RDF::LDP::NonRDFSource.to_uri) if
        non_rdf_source?
      headers << link_type_header(container_class) if container?
      headers
    end

    ##
    # @return [String] a string to insert into a Link header
    def link_type_header(uri)
      "<#{uri}>;rel=\"type\""
    end

    ##
    # Sets the last modified date/time to now
    #
    # @param transaction [RDF::Transaction] the transaction scope in which to
    #   apply changes. If none (or `nil`) is given, the change is made outside
    #   any transaction scope.
    def set_last_modified(transaction = nil)
      return metagraph.update([subject_uri, MODIFIED_URI, DateTime.now]) unless
        transaction

      # transactions do not support updates or pattern deletes, so we must
      # ask the Repository for the current last_modified to delete the
      # statement transactionally
      if last_modified
        transaction
          .delete RDF::Statement(subject_uri, MODIFIED_URI, last_modified,
                                 graph_name: metagraph_name)
      end

      transaction
        .insert RDF::Statement(subject_uri, MODIFIED_URI, DateTime.now,
                               graph_name: metagraph_name)
    end

    ##
    # Sets the interaction model to the URI for this resource's class
    def set_interaction_model(transaction)
      transaction.insert(RDF::Statement(subject_uri,
                                        RDF.type,
                                        self.class.to_uri,
                                        graph_name: metagraph.graph_name))
    end
  end
end
