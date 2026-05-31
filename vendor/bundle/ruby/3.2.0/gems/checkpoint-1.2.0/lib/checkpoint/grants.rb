# frozen_string_literal: true

# Note: we do not require db/grant because Sequel requires the connection
# to be set up before defining the model classes. The arrangment here
# assumes that DB.initialize! will have been called if the default model
# is to be used. In tests, that is done by spec/sequel_helper.rb. In an
# application, there should be an initializer that reads whatever appropriate
# configuration and does the initialization.

require "checkpoint/db"

module Checkpoint
  # The repository of grants -- a simple wrapper for the Sequel Datastore / grants table.
  class Grants
    def initialize(grants: Checkpoint::DB::Grant)
      @grants = grants
    end

    def for(agents, credentials, resources)
      where(agents, credentials, resources).all
    end

    def any?(agents, credentials, resources)
      where(agents, credentials, resources).first != nil
    end

    # Find grants of the given credentials on the given resources.
    #
    # This is useful for finding who should have particular access. Note that
    # this low-level interface returns the full grants, rather than a unique
    # set of agents.
    #
    # @return [Array<Grant>] the set of grants of any of the credentials on
    #   any of the resources
    def who(credentials, resources)
      DB::Query::CR.new(credentials, resources, **scope).all
    end

    # Find grants to the given agents on the given resources.
    #
    # This is useful for finding what actions may be taken on particular items.
    # Note that this low-level interface returns the full grants, rather than a
    # unique set of credentials.
    #
    # @return [Array<Grant>] the set of grants to any of the agents on any of
    #   the resources
    def what(agents, resources)
      DB::Query::AR.new(agents, resources, **scope).all
    end

    # Find grants to the given agents of the given credentials.
    #
    # This is useful for finding which resources may acted upon. Note that this
    # low-level interface returns the full grants, rather than a unique set of
    # resources.
    #
    # @return [Array<Grant>] the set of grants of any of the credentials to
    #   any of the agents
    def which(agents, credentials)
      DB::Query::AC.new(agents, credentials, **scope).all
    end

    # Grant a credential.
    #
    # This method takes a single agent, credential, and resource to create a
    # grant. They are not expanded, though they may be general (e.g., an
    # agent for users of an instituion or a wildcard for resources of some type).
    #
    # @param agent [Agent] the agent to whom the credential should be granted
    # @param credential [Credential] the credential to grant
    # @param resource [Resource] the resource to which the credential should apply
    # @return [Grant] the saved Grant; nil if the save fails
    def grant!(agent, credential, resource)
      grants.from(agent, credential, resource).save
    end

    # Revoke a credential.
    #
    # Take care to note that this follows the same matching semantics as
    # {.for}. There is no expansion done here, but anything that matches what
    # is supplied will be deleted. Of particular note is the default wildcard
    # behavior of {Checkpoint::Resource::Resolver}: if a specific resource has
    # been expanded by the resolver, and the array of the resource, a type
    # wildcard, and the any-resource wildcard (as used for inherited matching)
    # is supplied, the results may be surprising where there are grants at
    # specific and general levels.
    #
    # In general, the parameters should not have been expanded. If the intent
    # is to revoke a general grant, the general details should be supplied,
    # and likewise for the specific case.
    #
    # Applications should interact with the {Checkpoint::Authority}, which
    # exposes a more application-oriented interface. This repository should be
    # considered internal to Checkpoint.
    #
    # @param agents [Agent|Array] the agent or agents to match for deletion
    # @param credentials [Credential|Array] the credential or credentials to match for deletion
    # @param resources [Resource|Array] the resource or resources to match for deletion
    # @return [Integer] the number of Grants deleted
    def revoke!(agents, credentials, resources)
      where(agents, credentials, resources).delete
    end

    private

    def scope
      {scope: grants}
    end

    def where(agents, credentials, resources)
      DB::Query::ACR.new(agents, credentials, resources, **scope)
    end

    attr_reader :grants
  end
end
