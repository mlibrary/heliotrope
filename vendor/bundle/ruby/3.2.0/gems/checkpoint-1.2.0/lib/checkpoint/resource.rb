# frozen_string_literal: true

require "checkpoint/resource/token"
require "checkpoint/resource/all_of_type"
require "checkpoint/resource/all_of_any_type"
require "checkpoint/resource/any_entity"
require "checkpoint/resource/any_entity_of_type"

module Checkpoint
  # A Resource is any application object that should be considered for
  # restricted access.
  #
  # Most commonly, these will be the core domain objects that are created by
  # users ("model instances", to use Rails terminology), but this is not a
  # requirement. A Resource can represent a fixed item in the system such as
  # the administrative password, where there might be a single 'update'
  # permission to change various elements of configuration. It might also be
  # something like a section of a site as set up in a config file.
  #
  # In modeling an application, it is not always obvious whether a concept
  # should be a {Credential} or a {Resource}, so take care to evaluate the
  # options. As an example, consider access to derivatives of a high-quality
  # media object based on subscription level. It may make more sense for a
  # given application to model access to a fixed set of profiles (e.g., mobile,
  # standard, premium) as credentials and named concepts that will appear
  # throughout the codebase. For an application where the profiles are more
  # dynamic, it may make more sense to model them as resources that can be
  # listed and updated by configuration or at runtime, with a fixed set of
  # permissions (e.g., preview, stream, download).
  #
  # Checkpoint does not force this decision to be made in one way for every
  # application, but provides the concepts of permission mapping and resource
  # resolution to accommodate whatever fixed, dynamic, or inherited modeling is
  # most appropriate for the credentials and resources of an application.
  class Resource
    attr_reader :entity

    # Special string to be used when granting or searching for grants on all
    # types or all resources
    ALL = "(all)"

    # Creates a Resource for this entity. Prefer the factory method {::from},
    # which applies default conversion rules. This constructor does not
    # consider whether the entity can covert itself with #to_resource.
    def initialize(entity)
      @entity = entity
    end

    # Covenience factory method to get a Resource that will match all entities
    # of any type.
    #
    # @return [AllOfAnyType] a wildcard resource instance
    def self.all
      AllOfAnyType.new
    end

    # Test whether this Resource represents all entities of all types.
    #
    # @see {::all}
    # @return [Boolean] true if this is a universal wildcard
    def all?
      type == ALL && id == ALL
    end

    # Convert this object to a Resource.
    #
    # For Checkpoint-supplied Resources, this is an identity operation,
    # but it allows consistent handling of the built-in types and
    # application-supplied types that will either implement this interface or
    # convert themselves to a built-in type. This removes the requirement to
    # extend Checkpoint types or bind to a specific conversion method.
    def to_resource
      self
    end

    # Get the resource type.
    #
    # Note that this is not necessarily a class/model type name. It can be
    # whatever type name is most useful for building tokens and inspecting
    # grants for this types. For example, there may be objects that have
    # subtypes that are not modeled as objects, decorators, or collection
    # objects (like a specialized type for the root of a tree) that should
    # be treated as the element type.
    #
    # If the entity implements `#resource_type`, we will use that. Otherwise,
    # we use the entity's class name.
    #
    # @return [String] the name of the entity's type after calling `#to_s` on it.
    def type
      if entity.respond_to?(:resource_type)
        entity.resource_type
      else
        entity.class
      end.to_s
    end

    # Get the resource ID.
    #
    # If the entity implements `#resource_id`, we will use that. Otherwise we
    # call `#id`. If the the entity does not implement either of these methods,
    # we raise a {NoIdentifierError}.
    #
    # @return [String] the entity's ID after calling `#to_s` on it.
    def id
      if entity.respond_to?(:resource_id)
        entity.resource_id
      elsif entity.respond_to?(:id)
        entity.id
      else
        raise NoIdentifierError, "No usable identifier on entity of type: #{entity.class}"
      end.to_s
    end

    # @return [Resource::Token] The token for this resource
    def token
      @token ||= Token.new(type, id)
    end

    # Convert this Resource into a wildcard representing all resources of this
    # type.
    #
    # @see Resource::AllOfType
    # @return [Resource] A Resource of the same type, but for all members
    def all_of_type
      Resource::AllOfType.new(type)
    end

    # Test whether this is a Resource wildcard of some specific type.
    #
    # @return [Boolean] true if this Resource has a specific type, but
    #   has the any/all ID, representing any Resources of that type
    def all_of_type?
      type != ALL && id == ALL
    end

    # Check whether two Resources refer to the same entity.
    # @param other [Resource] Another Resource to compare with
    # @return [Boolean] true when the other Resource's entity is the same as
    #   determined by comparing them with `#eql?`.
    def eql?(other)
      other.is_a?(Resource) && entity.eql?(other.entity)
    end

    # Check whether two Resources refer to the same entity by type and id.
    # @param other [Resource] Another Resource to compare with
    # @return [Boolean] true when the other Resource's type and id are equal.
    def ==(other)
      other.is_a?(Resource) && type == other.type && id == other.id
    end
  end
end
