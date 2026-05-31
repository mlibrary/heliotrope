# frozen_string_literal: true

module Checkpoint
  class Resource
    # A Resource Resolver is the bridge between concrete entity objects (like
    # model instances) and {Resource}s that the represent them.
    #
    # There are two basic operations:
    #
    # - Conversion maps an entity to a single Resource.
    # - Expansion maps an entity to all Resources for which a grant would allow
    #   an action.
    #
    # For example, this can be used to grant a credential on all items of a given
    # model class or to implement cascading permissions when all credentials for
    # a container should apply to the contained objects.
    #
    # This base implementation expands to three resources: one for the entity
    # itself, one for all entities of its type, and one for all entities of any
    # type. This provides a convenient and familiar construct, where a broader
    # grant (say, at the type level, or for "everything") implies a grant at
    # the more specific level.
    #
    # If an application needs to have broader grants that should be revocable
    # at a more specific level, this could be done in a specific policy, or by
    # implementing a custom resource resolver. The policy approach would be
    # localized to where it is needed, and is recommended in order to keep the
    # semantics of resource resolution consistent with other applications.
    #
    # A custom resource resolver could be useful particularly in cases where
    # there is equivalence or cascading across entities or types and those
    # rules need to be maintained consistently across policies or in support of
    # building administrative interfaces.
    #
    # Checkpoint does not enforce the decision of where necessary complexity
    # resides in an application, though the general notion is that application
    # policies should be the first place to add specialized rules. If rules are
    # more complex, base policies or delegation are helpful tools. And, if
    # there is even more complexity, Checkpoint allows its fundamental
    # semantics to be extended by implementing a custom resolver.
    class Resolver
      # Expand an application entity into a set of Resources for which a grant
      # would allow access.
      #
      # The entity will be expanded to three Resources:
      #
      # 1. A Resource for the specific entity, by conversion
      # 2. A {Resource::AllOfType} for the type of the entity, as by conversion
      # 3. A special {Resource::AllOfAnyType} to support zone-wide grants
      #
      # As an example, permission to download high quality versions of media
      # assets might be granted to a given user system wide (that is, for the
      # special 'all' resource). Implementing in this way, the credential would
      # be a specific permission in the domain (e.g., permission:high-quality),
      # and it would be checked when authorizing those downloads.
      #
      # An alternative approach would be to grant a generic permission (e.g.,
      # permission:download) to that user for a specific resource type modeling
      # the high quality version. Which is more appropriate depends on the
      # conceptual models and design of an application and Checkpoint does not
      # enforce one design decision over another.
      #
      # If these default extension mechanisms do not match an application's
      # needs, a custom implementation may be used with whatever resolution is
      # appropriate. This could be especially useful if it is commonly needed
      # to authorize actions on a specific resource, while permissions for it
      # should be inherited from a container resource. For some applications,
      # this approach may be more convenient than, for example, delegating to a
      # specific policy in the same way from multiple sections of the
      # application.
      def expand(entity)
        [convert(entity), convert(entity).all_of_type, Resource.all]
      end

      # Default conversion from an entity to a {Resource}.
      #
      # If the entity implements #to_resource, we will delegate to it. Otherwise,
      # we will instantiate a {Resource} with the supplied entity.
      #
      # Override this method to use a different or conditional Resource type.
      #
      # @return [Resource] the entity converted to a resource
      def convert(entity)
        if entity.respond_to?(:to_resource)
          entity.to_resource
        else
          Resource.new(entity)
        end
      end
    end
  end
end
