module RDF::LDP
  ##
  # An extension of `RDF::LDP::DirectContainer` implementing indirect
  # containment. Adds the concept of an inserted content relation to the
  # features of the direct container.
  #
  # Clients MUST provide exactly one `ldp:insertedContentRelation` statement in
  # each Indirect Container. If no `#inserted_content_relation` is given by the
  # client, we default to `ldp:MemberSubject`. If more than one is present,
  #
  # Attempts to POST resources without the appropriate content relation (or
  # with more than one) to an Indirect Container will fail with `Not
  # Acceptable`. LDP-NR's cannot be added since indirect membership is not well
  # defined for them, per _LDP 5.5.1.2_.
  #
  # @see https://www.w3.org/TR/ldp/#h-ldpic-indirectmbr for an explanation if
  #   indirect membership and limitiations surrounding LDP-NRs.
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-indirect-container
  #   definition of LDP Indirect Container
  class IndirectContainer < DirectContainer
    INSERTED_CONTENT_REL_URI = RDF::Vocab::LDP.insertedContentRelation.freeze
    MEMBER_SUBJECT_URI       = RDF::Vocab::LDP.MemberSubject.freeze

    def self.to_uri
      RDF::Vocab::LDP.IndirectContainer
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:indirect]
    end

    ##
    # Creates and inserts default relation triples if none are given.
    #
    # @see DirectContainer#create for information about the behavior and
    #   transactionality of this method.
    def create(input, content_type)
      super

      graph.transaction(mutable: true) do |tx|
        if inserted_content_statements.empty?
          tx.insert RDF::Statement(subject_uri,
                                   INSERTED_CONTENT_REL_URI,
                                   MEMBER_SUBJECT_URI)
        end
      end

      self
    end

    ##
    # Gives the inserted content relation for the indirect container. If none is
    # present in the container state, we add `ldp:MemberSubject`, effectively
    # treating this LDP-IC as an LDP-DC.
    #
    # @return [RDF::URI] the inserted content relation; either a predicate term
    #   or `ldp:MemberSubject`
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple inserted content relations
    #   exist.
    #
    # @see https://www.w3.org/TR/ldp/#dfn-membership-triples
    def inserted_content_relation
      statements = inserted_content_statements
      return statements.first.object if statements.count == 1

      raise(NotAcceptable, 'An LDP-IC MUST have exactly ' \
                           'one inserted content relation triple; found ' \
                           "#{statements.count}.")
    end

    private

    def inserted_content_statements
      graph.query([subject_uri, INSERTED_CONTENT_REL_URI, nil])
           .statements
    end

    def process_membership_resource(resource, transaction = nil)
      member = member_derived_uri(resource, transaction)
      super(resource, transaction, member)
    end

    def member_derived_uri(resource, transaction = nil)
      predicate = inserted_content_relation
      return resource.to_uri if predicate == MEMBER_SUBJECT_URI

      if resource.non_rdf_source?
        raise(NotAcceptable, "#{resource.to_uri} is an LDP-NR; cannot add " \
                             'it to an IndirectContainer with a content '   \
                             'relation.')
      end

      target = transaction || resource.graph
      statements = target.query([resource.subject_uri, predicate, :o])
      return statements.first.object if statements.count == 1

      raise(NotAcceptable, "#{statements.count} inserted content" \
                           "#{predicate} found on #{resource.to_uri}")
    end
  end
end
