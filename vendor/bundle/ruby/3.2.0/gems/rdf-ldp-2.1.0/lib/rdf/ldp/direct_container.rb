module RDF::LDP
  ##
  # An extension of `RDF::LDP::Container` implementing direct containment.
  # This adds the concepts of a membership resource, predicate, and triples to
  # the Basic Container's containment triples.
  #
  # When the membership resource is an `RDFSource`, the membership triple is
  # added/removed from its graph when the resource created/deleted within the
  # container. When the membership resource is a `NonRDFSource`, the triple is
  # added/removed on its description's graph instead.
  #
  # A membership constant URI and membership predicate MUST be specified as
  # described in LDP--exactly one of each. If none is given, we default to
  # the container itself as a membership resource and `ldp:member` as predicate.
  # If more than one of either is given, all `#add/#remove` (POST/DELETE)
  # requests will fail.
  #
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-direct-container
  #   definition of LDP Direct Container
  class DirectContainer < Container
    MEMBER_URI              = RDF::Vocab::LDP.member.freeze
    MEMBERSHIP_RESOURCE_URI = RDF::Vocab::LDP.membershipResource.freeze

    RELATION_TERMS = [RDF::Vocab::LDP.hasMemberRelation.freeze,
                      RDF::Vocab::LDP.isMemberOfRelation.freeze].freeze

    def self.to_uri
      RDF::Vocab::LDP.DirectContainer
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:direct]
    end

    ##
    # Creates and inserts default relation triples if none are given.
    #
    # @note the addition of default triples is handled in a separate
    #   transaction. It is possible for the second transaction to fail, causing
    #   the resource to persist in an invalid state. It is also possible for a
    #   read to occur between the two transactions.
    # @todo Make atomic. Consider just raising an error instead of adding
    #   triples. There's a need to handle this issue for repositories with
    #   snapshot reads, as well as those without.
    #
    # @see Container#create
    def create(input, content_type)
      super

      graph.transaction(mutable: true) do |tx|
        tx.insert(default_member_relation_statement) if
          member_relation_statements.empty?
        tx.insert(default_membership_resource_statement) if
          membership_resource_statements.empty?
      end

      self
    end

    ##
    # Adds a member `resource` to the container. Handles containment and adds
    # membership triple to the memebership resource.
    #
    # @see RDF::LDP::Container#add
    def add(resource, transaction = nil)
      process_membership_resource(resource,
                                  transaction) do |container, quad, subject|
        super(subject, transaction) # super handles nil transaction case
        target = transaction || container.graph
        target.insert(quad)
      end
      self
    end

    ##
    # Removes a member `resource` to the container. Handles containment and
    # removes membership triple to the memebership resource.
    #
    # @see RDF::LDP::Container#remove
    def remove(resource, transaction = nil)
      process_membership_resource(resource,
                                  transaction) do |container, quad, subject|
        super(subject, transaction) # super handles nil transaction case
        target = transaction || container.graph
        target.delete(quad)
      end
      self
    end

    ##
    # Gives the membership constant URI. If none is present in the container
    # state, we add the current resource as a membership constant.
    #
    # @return [RDF::URI] the membership constant uri for the container
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple membership constant uris
    #   exist
    #
    # @see https://www.w3.org/TR/ldp/#dfn-membership-triples
    def membership_constant_uri
      statements = membership_resource_statements
      return statements.first.object if statements.count == 1

      raise(NotAcceptable, 'An LDP-DC MUST have exactly one membership ' \
                           "resource; found #{statements.count}.")
    end

    ##
    # Gives the membership predicate. If none is present in the container
    # state, we add the current resource as a membership constant.
    #
    # @return [RDF::URI] the membership predicate
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple membership predicates exist
    #
    # @see https://www.w3.org/TR/ldp/#dfn-membership-predicate
    def membership_predicate
      statements = member_relation_statements
      return statements.first.object if statements.count == 1

      raise(NotAcceptable, 'An LDP-DC MUST have exactly one member ' \
                           "relation triple; found #{statements.count}.")
    end

    ##
    # @param [RDF::Term] resource  a member for this container
    #
    # @return [RDF::URI] the membership triple representing membership of the
    #   `resource` parameter in this container
    #
    # @see https://www.w3.org/TR/ldp/#dfn-membership-triples
    def make_membership_triple(resource)
      predicate = membership_predicate
      return RDF::Statement(membership_constant_uri, predicate, resource) if
        member_relation_statements.first.predicate == RELATION_TERMS.first
      RDF::Statement(resource, predicate, membership_constant_uri)
    end

    private

    def membership_resource_statements
      graph.query([subject_uri, MEMBERSHIP_RESOURCE_URI, :o])
    end

    def member_relation_statements
      graph.query([subject_uri, nil, nil]).select do |st|
        RELATION_TERMS.include?(st.predicate)
      end
    end

    def membership_resource
      uri = membership_constant_uri
      uri = uri.fragment ? (uri.root / uri.request_uri) : uri
      resource = RDF::LDP::Resource.find(uri, @data)
      return resource.description if resource.non_rdf_source?
      resource
    end

    def process_membership_resource(resource, _transaction = nil, member = nil)
      membership_triple = make_membership_triple((member || resource).to_uri)

      membership_triple.graph_name = subject_uri
      yield(self, membership_triple, resource) if block_given?
    end

    def default_membership_resource_statement
      RDF::Statement(subject_uri, MEMBERSHIP_RESOURCE_URI, subject_uri)
    end

    def default_member_relation_statement
      RDF::Statement(subject_uri, RELATION_TERMS.first, MEMBER_URI)
    end
  end
end
