# frozen_string_literal: true
require 'rdf'
require 'active_triples/version'
require 'active_support'

##
# An ActiveModel compliant ObjectGraphMapper for RDF data. 
# 
# Models graphs as `RDFSources` with property/attribute configuration, 
# accessors, and other methods to support Linked Data in a Ruby enviornment. 
#
# @example modeling a simple resource
#   class Thing
#     include  ActiveTriples::RDFSource
#     configure :type => RDF::OWL.Thing, :base_uri => 'http://example.org/things#'
#     property :title, :predicate => RDF::DC.title
#     property :description, :predicate => RDF::DC.description
#   end
#
#   obj = Thing.new('123')
#   obj.title = 'Resource'
#   obj.description = 'A resource.'
#   obj.dump :ntriples 
#    # => "<http://example.org/things#123> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .\n<http://example.org/things#123> <http://purl.org/dc/terms/title> \"Resource\" .\n<http://example.org/things#123> <http://purl.org/dc/terms/description> \"A resource.\" .\n"
#
# @see http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/#change-over-time 
#   RDF Concepts and Abstract Syntax for an informal definition of an RDF 
#   Source.
module ActiveTriples
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :RDFSource
    autoload :Resource
    autoload :List
    autoload :Relation
    autoload :Configurable
    autoload :Persistable
    autoload :Properties
    autoload :PropertyBuilder
    autoload :Reflection
    autoload :Repositories
    autoload :NodeConfig
    autoload :NestedAttributes
    autoload :Identifiable
    autoload :Configuration
    autoload :Schema
    autoload :Property
    autoload :ExtensionStrategy

    # persistence strategies
    autoload :PersistenceStrategy,
             'active_triples/persistence_strategies/persistence_strategy'
    autoload :ParentStrategy,
             'active_triples/persistence_strategies/parent_strategy'
    autoload :RepositoryStrategy,
             'active_triples/persistence_strategies/repository_strategy'

    # error classes
    autoload :UndefinedPropertyError
  end
  
  ##
  # Raised when a declared repository doesn't have a definition
  class RepositoryNotFoundError < StandardError
  end

  ##
  # Converts a string for a class or module into a a constant. This will find
  # classes in or above a given container class.
  #
  # @example finding a class in Kernal
  #    ActiveTriples.class_from_string('MyClass') # => MyClass
  #
  # @example finding a class in a module
  #    ActiveTriples.class_from_string('MyClass', MyModule) 
  #    # => MyModule::MyClass
  #
  # @example when a class exists above the module, but not in it
  #    ActiveTriples.class_from_string('Object', MyModule) 
  #    # => Object
  #
  # @param class_name [String]
  # @param container_class
  #
  # @return [Class]
  def self.class_from_string(class_name, container_class=Kernel)
    container_class = container_class.name if container_class.is_a? Module
    container_parts = container_class.split('::')
    (container_parts + class_name.split('::'))
      .flatten.inject(Kernel) do |mod, class_name|
      if mod == Kernel
        Object.const_get(class_name)
      elsif mod.const_defined? class_name.to_sym
        mod.const_get(class_name)
      else
        container_parts.pop
        class_from_string(class_name, container_parts.join('::'))
      end
    end
  end

  ##
  # A simplified, Belgian version of this software
  def self.ActiveTripels
    puts <<-eos

        ###########
        ******o****
         **o******
          *******
           \\***/
            | |
            ( )
            / \\
        ,---------.

eos
"Yum"
  end
end
