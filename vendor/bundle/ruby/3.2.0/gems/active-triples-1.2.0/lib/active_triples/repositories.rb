# frozen_string_literal: true
module ActiveTriples
  ##
  # Defines module methods for registering an RDF::Repository for
  # persistence of Resources.
  #
  # This allows any triplestore (or other storage platform) with an
  # RDF::Repository implementation to be used for persistence of
  # resources that will be shared between ActiveFedora::Base objects.
  #
  # @example registering a repository
  #
  #    ActiveTriples::Repositories.add_repository :defaulst, RDF::Repository.new
  #
  # Multiple repositories can be registered to keep different kinds of
  # resources seperate. This is configurable on subclasses of Resource
  # at the class level.
  #
  # @see Configurable
  module Repositories

    ##
    # Register a repository to be configured by name
    #
    # @param name [Symbol]
    # @param repo [RDF::Repository]
    #
    # @return [RDF::Repository] gives the original repository on success
    #
    # @raise [ArgumentError] raised if the repository is not an `RDF::Repository`
    def add_repository(name, repo)
      raise ArgumentError, "Repositories must be an RDF::Repository" unless 
        repo.kind_of? RDF::Repository
      repositories[name] = repo
    end
    module_function :add_repository

    ##
    # Delete existing name, repository pairs from the registry hash
    #
    # @return [Hash<Symbol, Repository>] the now empty repository registry hash
    def clear_repositories!
      @repositories = {}
    end
    module_function :clear_repositories!

    ##
    # @return [Hash<Symbol, Repository>] a hash of currrently registered names 
    #   and repositories
    def repositories
      @repositories ||= {}
    end
    module_function :repositories

    ##
    # Check for the specified rdf_subject in the specified repository
    # defaulting to search all registered repositories.
    #
    # @param [String] rdf_subject
    # @param [Symbol] repository name
    # 
    # @return [Boolean] true if the repository contains at least one statement 
    #   with the given subject term
    def has_subject?(rdf_subject, repo_name=nil)
      search_repositories = [repositories[repo_name]] if repo_name
      search_repositories ||= repositories.values
      found = false
      search_repositories.each do |repo|
        found = repo.has_subject? rdf_subject
        break if found
      end
      found
    end
    module_function :has_subject?
  end
end
