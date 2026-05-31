module RDF::LDP
  ##
  # An LDP Basic Container. This also serves as a base class for other
  # container types. Containers are implemented as `RDF::LDP::RDFSources` with
  # the ability to contain other resources.
  #
  # Containers respond to `#post`, allowing new resources to be added to them.
  # On the public interface (not running through HTTP/`#request`), this is
  # supported by `#add` and `#remove`.
  #
  # Containers will throw errors when attempting to edit them in conflict with
  # LDP's restrictions on changing containment triples.
  #
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-container definition
  #   of LDP Container
  class Container < RDFSource
    ##
    # @return [RDF::URI] uri with lexical representation
    #   'https://www.w3.org/ns/ldp#Container'
    def self.to_uri
      RDF::Vocab::LDP.Container
    end

    ##
    # @return [Boolean] whether this is an ldp:Container
    def container?
      true
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:basic]
    end

    ##
    # Create with validation as required for the LDP container.
    #
    # @raise [RDF::LDP::Conflict] if the create inserts triples that are not
    #   allowed by LDP for the container type
    # @see RDFSource#create
    def create(input, content_type, &block)
      super do |transaction|
        validate_triples!(transaction)
        yield transaction if block_given?
      end
      self
    end

    ##
    # Updates with validation as required for the LDP container.
    #
    # @raise [RDF::LDP::Conflict] if the update edits triples that are not
    #   allowed by LDP for the container type
    # @see RDFSource#update
    def update(input, content_type, &block)
      super do |transaction|
        validate_triples!(transaction)
        yield transaction if block_given?
      end
      self
    end

    ##
    # Adds a member `resource` to the container. Handles containment and
    # membership triples as appropriate for the container type.
    #
    # If a transaction is passed as the second argument, the additon of the
    # containment triple is completed when the transaction closes; otherwise it
    # is handled atomically.
    #
    # @param [RDF::Term] resource
    #   a new member for this container
    # @param transaction [RDF::Transaction] transaction
    #   an active transaction as context for the addition
    # @return [Container] self
    def add(resource, transaction = nil)
      add_containment_triple(resource.to_uri, transaction)
    end

    ##
    # Removes a member `resource` from the container. Handles containment and
    # membership triples as appropriate for the container type.
    #
    # If a transaction is passed as the second argument, the removal of the
    # containment triple is completed when the transaction closes; otherwise it
    # is handled atomically.
    #
    # @param [RDF::Term] resource
    #   a new member for this container
    # @param transaction [RDF::Transaction] transaction
    #   an active transaction as context for the removal
    # @return [Container] self
    def remove(resource, transaction = nil)
      remove_containment_triple(resource.to_uri, transaction)
    end

    ##
    # @return [RDF::Query::Enumerator] the containment triples
    def containment_triples
      graph.query([subject_uri, CONTAINS_URI, nil]).statements
    end

    ##
    # @param [RDF::Statement] statement
    #
    # @return [Boolean] true if the containment triple exists
    def has_containment_triple?(statement)
      !containment_triples.find { |t| statement == t }.nil?
    end

    ##
    # Adds a containment triple for `resource` to the container's `#graph`.
    #
    # If a transaction is passed as the second argument, the triple is added to
    # the transaction's inserts; otherwise it is added directly to `#graph`.
    #
    # @param resource [RDF::Term] a new member for this container
    # @param transaction [RDF::Transaction]
    # @return [Container] self
    def add_containment_triple(resource, transaction = nil)
      target = transaction || graph
      target.insert make_containment_triple(resource)
      set_last_modified(transaction) # #set_last_modified handles nil case
      self
    end

    ##
    # Remove a containment triple for `resource` to the container's `#graph`.
    #
    # If a transaction is passed as the second argument, the triple is added to
    # the transaction's deletes; otherwise it is deleted directly from `#graph`.
    #
    # @param resource [RDF::Term] a member to remove from this container
    # @param transaction [RDF::Transaction]
    # @return [Container] self
    def remove_containment_triple(resource, transaction = nil)
      target = transaction || graph
      target.delete(make_containment_triple(resource))
      set_last_modified(transaction) # #set_last_modified handles nil case
      self
    end

    ##
    # @param [RDF::Term] resource
    #   a member to be represented in the containment triple
    #
    # @return [RDF::URI]
    #   the containment triple, with a graph_name pointing
    #   to `#graph`
    def make_containment_triple(resource)
      RDF::Statement(subject_uri, CONTAINS_URI, resource,
                     graph_name: subject_uri)
    end

    private

    def patch(_status, headers, env)
      check_precondition!(env)
      method = patch_types[env['CONTENT_TYPE']]

      raise UnsupportedMediaType unless method

      temp_data  = RDF::Repository.new << graph.statements
      temp_graph = RDF::Graph.new(graph_name: graph.name, data: temp_data)
      send(method, env['rack.input'], temp_graph)

      validate_statements!(temp_graph)
      graph.clear!
      graph << temp_graph.statements

      set_last_modified
      [200, update_headers(headers), self]
    end

    ##
    # Handles a POST request. Parses a graph in the body of `env` and treats all
    # statements in that graph (irrespective of any graph names) as constituting
    # the initial state of the created source.
    #
    # @raise [RDF::LDP::RequestError] when creation fails
    #
    # @return [Array<Fixnum, Hash<String, String>, #each] a new Rack response
    #   array.
    def post(_status, headers, env)
      klass = self.class.interaction_model(env.fetch('HTTP_LINK', ''))
      slug = env['HTTP_SLUG']
      slug = klass.gen_id if slug.nil? || slug.empty?
      raise(NotAcceptable, 'Refusing to create resource with `#` in Slug') if
        slug.include? '#'

      id = (subject_uri / slug).canonicalize

      created = klass.new(id, @data)

      created.create(env['rack.input'], env['CONTENT_TYPE']) do |transaction|
        add(created, transaction)
      end

      headers['Location'] = created.subject_uri.to_s
      [201, created.send(:update_headers, headers), created]
    end

    def validate_triples!(transaction)
      existing_triples = containment_triples.to_a

      tx_containment = transaction.query({subject: subject_uri,
                                         predicate: CONTAINS_URI})

      tx_containment.each do |statement|
        unless existing_triples.include?(statement)
          raise(Conflict, 'Attempted to write unacceptable LDP ' \
                          "containment-triple: #{statement}")
        end
      end

      deletes = existing_triples.reject { |st| tx_containment.include?(st) }

      return if deletes.empty?

      raise(Conflict, 'Cannot remove containment triples in updates. ' \
                      "Attepted to remove #{deletes}")
    end

    ##
    # supports Patch.
    def validate_statements!(statements)
      existing_triples = containment_triples.to_a
      statements.query({subject: subject_uri, predicate: CONTAINS_URI}) do |st|
        existing_triples.delete(st) do
          raise(Conflict, 'Attempted to write unacceptable LDP ' \
                          "containment-triple: #{st}")
        end
      end

      return if existing_triples.empty?

      raise(Conflict, 'Cannot remove containment triples in updates. ' \
                      "Attepted to remove #{existing_triples}")
    end
  end
end
