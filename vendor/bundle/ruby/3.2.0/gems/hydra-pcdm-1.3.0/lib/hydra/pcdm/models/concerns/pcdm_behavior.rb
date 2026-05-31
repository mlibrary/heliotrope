module Hydra::PCDM
  ##
  # Implements behavior for PCDM objects. This behavior is intended for use with
  # another concern completing the set of defined behavior for a PCDM class
  # (e.g. `PCDM::ObjectBehavior` or `PCDM::CollectionBehavior`).
  #
  # A class mixing in this behavior needs to implement {.type_validator},
  # returning a validator class.
  #
  # @example Defining a minimal PCDM-like thing
  #   class MyAbomination < ActiveFedora::Base
  #     def type_validator
  #       Hydra::PCDM::Validators::PCDMValidator
  #     end
  #
  #     include Hydra::PCDM::PcdmBehavior
  #   end
  #
  #   abom = MyAbomination.create
  #
  # @see ActiveFedora::Base
  # @see Hydra::PCDM::Validators
  module PcdmBehavior
    extend ActiveSupport::Concern

    included do
      ##
      # @macro [new] ordered_aggregation
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      ordered_aggregation :members,
                          has_member_relation: Vocab::PCDMTerms.hasMember,
                          class_name: 'ActiveFedora::Base',
                          type_validator: type_validator,
                          through: :list_source

      ##
      # @macro [new] indirectly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      indirectly_contains :related_objects, has_member_relation: RDF::Vocab::ORE.aggregates,
                                            inserted_content_relation: RDF::Vocab::ORE.proxyFor, class_name: 'ActiveFedora::Base',
                                            through: 'ActiveFedora::Aggregation::Proxy', foreign_key: :target,
                                            type_validator: Validators::PCDMObjectValidator

      ##
      # @macro [new] indirectly_contains
      #   @!method $1
      #     @return [ActiveFedora::Associations::ContainerProxy]
      indirectly_contains :member_of_collections,
                          has_member_relation: Vocab::PCDMTerms.memberOf,
                          inserted_content_relation: RDF::Vocab::ORE.proxyFor,
                          class_name: 'ActiveFedora::Base',
                          through: 'ActiveFedora::Aggregation::Proxy',
                          foreign_key: :target,
                          type_validator: Validators::PCDMCollectionValidator
    end

    ##
    # @see ActiveSupport::Concern
    module ClassMethods
      ##
      # @return [#validate!] a validator object
      def type_validator
        @type_validator ||= Validators::CompositeValidator.new(
          super,
          Validators::PCDMValidator,
          Validators::AncestorValidator
        )
      end
    end

    ##
    # @return [Enumerable<ActiveFedora::Base>]
    def member_of
      return [] if id.nil?
      ActiveFedora::Base.where(Config.indexing_member_ids_key => id)
    end

    ##
    # Gives the subset of #members that are PCDM objects
    #
    # @return [Enumerable<PCDM::ObjectBehavior>] an enumerable over the members
    #   that are PCDM objects
    def objects
      members.select(&:pcdm_object?)
    end

    ##
    # Gives a subset of #member_ids, where all elements are PCDM objects.
    # @return [Enumerable<String>] the object ids
    def object_ids
      objects.map(&:id)
    end

    ##
    # Gives a subset of {#ordered_members}, where all elements are PCDM objects.
    #
    # @return [Enumerable<PCDM::ObjectBehavior>]
    def ordered_objects
      ordered_members.to_a.select(&:pcdm_object?)
    end

    ##
    # @return [Enumerable<String>] an ordered list of member ids
    def ordered_object_ids
      ordered_objects.map(&:id)
    end

    ##
    # @return [Enumerable<Hydra::PCDM::CollectionBehavior>] the collections the
    #   object is a member of.
    def in_collections
      member_of.select(&:pcdm_collection?).to_a
    end

    # @return [Enumerable<String>] ids for collections the object is a member of
    def in_collection_ids
      in_collections.map(&:id)
    end

    ##
    # @param [ActiveFedora::Base] potential_ancestor  the resource to check for
    #   ancestorship
    # @return [Boolean] whether the argument is an ancestor of the object
    def ancestor?(potential_ancestor)
      ::Hydra::PCDM::AncestorChecker.former_is_ancestor_of_latter?(potential_ancestor, self)
    end
  end
end
