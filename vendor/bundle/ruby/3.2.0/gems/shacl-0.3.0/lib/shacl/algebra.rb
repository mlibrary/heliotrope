$:.unshift(File.expand_path("../..", __FILE__))
require 'sxp'
require_relative "algebra/operator"
require_relative "algebra/constraint_component"

module SHACL
  # Based on the SPARQL Algebra, operators for executing a patch
  module Algebra
    autoload :AndConstraintComponent,               'shacl/algebra/and.rb'
    autoload :NodeShape,                            'shacl/algebra/node_shape.rb'
    autoload :NotConstraintComponent,               'shacl/algebra/not.rb'
    autoload :OrConstraintComponent,                'shacl/algebra/or.rb'
    autoload :PatternConstraintComponent,           'shacl/algebra/pattern.rb'
    autoload :PropertyShape,                        'shacl/algebra/property_shape.rb'
    autoload :QualifiedMaxCountConstraintComponent, 'shacl/algebra/qualified_value.rb'
    autoload :QualifiedMinCountConstraintComponent, 'shacl/algebra/qualified_value.rb'
    autoload :QualifiedValueConstraintComponent,    'shacl/algebra/qualified_value.rb'
    autoload :Shape,                                'shacl/algebra/shape.rb'
    autoload :SPARQLConstraintComponent,            'shacl/algebra/sparql_constraint.rb'
    autoload :XoneConstraintComponent,              'shacl/algebra/xone.rb'

    def self.from_json(operator, **options)
      raise SHACL::Error, "from_json: operator not a Hash: #{operator.inspect}" unless operator.is_a?(Hash)

      # If operator is a hash containing @list, it is a single array value.
      # Note: context does not use @container: @list on this terms to preserve cardinality expectations
      return operator['@list'].map {|e| from_json(e, **options)} if operator.key?('@list')

      type = operator.fetch('type', [])
      type << (operator["path"] ? 'PropertyShape' : 'NodeShape') if type.empty?
      klass = case
      when type.include?('NodeShape') then NodeShape
      when type.include?('PropertyShape') then PropertyShape
      else raise SHACL::Error, "from_json: unknown type #{type.inspect}"
      end

      klass.from_json(operator, **options)
    end
  end
end


