module SHACL::Algebra
  ##
  class Shape < Operator
    NAME = :Shape

    ##
    # Returns the nodes matching this particular shape, based upon the shape properties:
    #  * `targetNode`
    #  * `targetClass`
    #  * `targetSubjectsOf`
    #  * `targetObjectsOf`
    #  * `id` – where `type` includes `rdfs:Class`
    #
    # @return [Array<RDF::Term>]
    def targetNodes
      (Array(@options[:targetNode]) +
      Array(@options[:targetClass]).map do |cls|
        graph.query({predicate: RDF.type, object: cls}).subjects
      end +
      Array(@options[:targetSubjectsOf]).map do |pred|
        graph.query({predicate: pred}).subjects
      end +
      Array(@options[:targetObjectsOf]).map do |pred|
        graph.query({predicate: pred}).objects
      end + (
        Array(type).include?(RDF::RDFS.Class) ?
          graph.query({predicate: RDF.type, object: id}).subjects :
          []
      )).flatten.uniq
    end

    ##
    # Builin evaluators. These evaulators may be used on either NodeShapes or PropertyShapes.
    ##

    # Specifies that each value node is a SHACL instance of a given type.
    #
    # @example
    #   ex:ClassExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob, ex:Alice, ex:Carol ;
    #   	sh:property [
    #   		sh:path ex:address ;
    #   		sh:class ex:PostalAddress ;
    #   	] .
    #
    # @param [Array<RDF::URI>] types The type expected for each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_class(types, node, path, value_nodes, **options)
      value_nodes.map do |n|
        has_type = n.resource? && begin
          objects = graph.query({subject: n, predicate: RDF.type}).objects
          types.all? {|t| objects.include?(t)}
        end
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_type} of class #{type.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless has_type),
          component: RDF::Vocab::SHACL.ClassConstraintComponent,
          **options)
      end.flatten.compact
    end

    # Specifies a condition to be satisfied with regards to the datatype of each value node.
    #
    # @example
    #   ex:DatatypeExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Alice, ex:Bob, ex:Carol ;
    #   	sh:property [
    #   		sh:path ex:age ;
    #   		sh:datatype xsd:integer ;
    #   	] .
    #
    #
    # @param [RDF::URI] datatype the expected datatype of each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @return [Array<SHACL::ValidationResult>]
    def builtin_datatype(datatype, node, path, value_nodes, **options)
      datatype = datatype.first if datatype.is_a?(Array)
      value_nodes.map do |n|
        has_datatype = n.literal? && n.datatype == datatype && n.valid?
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_datatype} a valid literal with datatype #{datatype.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless has_datatype),
          component: RDF::Vocab::SHACL.DatatypeConstraintComponent,
          **options)
      end.flatten.compact
    end

    # Specifies the condition that the set of value nodes is disjoint with the set of objects of the triples that have the focus node as subject and the value of sh:disjoint as predicate.
    #
    # @example
    #   ex:DisjointExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:USA, ex:Germany ;
    #   	sh:property [
    #   		sh:path ex:prefLabel ;
    #   		sh:disjoint ex:altLabel ;
    #   	] .
    #
    # @param [Array<RDF::URI>] properties the properties of the focus node whose values must be disjoint with the value nodes.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_disjoint(properties, node, path, value_nodes, **options)
      disjoint_nodes = properties.map do |prop|
        graph.query({subject: node, predicate: prop}).objects
      end.flatten.compact
      value_nodes.map do |n|
        has_value = disjoint_nodes.include?(n)
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_value} disjoint with #{disjoint_nodes.to_sxp}",
          resultSeverity: (options.fetch(:severity) if has_value),
          component: RDF::Vocab::SHACL.DisjointConstraintComponent,
          **options)
      end.flatten.compact
    end

    # Specifies the condition that the set of all value nodes is equal to the set of objects of the triples that have the focus node as subject and the value of sh:equals as predicate.
    #
    # @example
    #   ex:EqualExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob ;
    #   	sh:property [
    #   		sh:path ex:firstName ;
    #   		sh:equals ex:givenName ;
    #   	] .
    #
    # @param [RDF::URI] property the property of the focus node whose values must be equal to some value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_equals(property, node, path, value_nodes, **options)
      property = property.first if property.is_a?(Array)
      equal_nodes = graph.query({subject: node, predicate: property}).objects
      (value_nodes.map do |n|
        has_value = equal_nodes.include?(n)
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_value} a value in #{equal_nodes.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless has_value),
          component: RDF::Vocab::SHACL.EqualsConstraintComponent,
          **options)
      end +
      equal_nodes.map do |n|
        !value_nodes.include?(n) ?
          not_satisfied(focus: node, path: path,
            value: n,
            message: "should have a value in #{value_nodes.to_sxp}",
            resultSeverity: options.fetch(:severity),
            component: RDF::Vocab::SHACL.EqualsConstraintComponent,
            **options) :
          nil
      end).flatten.compact
    end

    # Specifies the condition that at least one value node is equal to the given RDF term.
    #
    # @example
    #   ex:StanfordGraduate
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Alice ;
    #   	sh:property [
    #   		sh:path ex:alumniOf ;
    #   		sh:hasValue ex:Stanford ;
    #   	] .
    #
    # @param [RDF::URI] term the term that must be a value of a value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_hasValue(term, node, path, value_nodes, **options)
      term = term.first if term.is_a?(Array)
      has_value = value_nodes.include?(term)
      [satisfy(focus: node, path: path,
        message: "is#{' not' unless has_value} the value #{term.to_sxp}",
        resultSeverity: (options.fetch(:severity) unless has_value),
        component: RDF::Vocab::SHACL.HasValueConstraintComponent,
        **options)]
    end

    # Specifies the condition that each value node is a member of a provided SHACL list.
    #
    # @example
    #   ex:InExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:RainbowPony ;
    #   	sh:property [
    #   		sh:path ex:color ;
    #   		sh:in ( ex:Pink ex:Purple ) ;
    #   	] .
    #
    # @param [RDF::URI] list the list which must contain the value nodes..
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_in(list, node, path, value_nodes, **options)
      value_nodes.map do |n|
        has_value = list.include?(n)
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_value} a value in #{list.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless has_value),
          component: RDF::Vocab::SHACL.InConstraintComponent,
          **options)
      end.flatten.compact
    end

    # The condition specified by sh:languageIn is that the allowed language tags for each value node are limited by a given list of language tags.
    #
    # @example
    #   ex:NewZealandLanguagesShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Mountain, ex:Berg ;
    #   	sh:property [
    #   		sh:path ex:prefLabel ;
    #   		sh:languageIn ( "en" "mi" ) ;
    #   	] .
    #
    # @param [Array<RDF::URI>] datatypes the expected datatype of each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @return [Array<SHACL::ValidationResult>]
    def builtin_languageIn(datatypes, node, path, value_nodes, **options)
      value_nodes.map do |n|
        has_language = n.literal? && datatypes.any? {|l| n.language.to_s.start_with?(l)}
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless has_language} a literal with a language in #{datatypes.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless has_language),
          component: RDF::Vocab::SHACL.LanguageInConstraintComponent,
          **options)
      end.flatten.compact
    end

    # Compares value nodes to be < than the specified value.
    #
    # @example
    #   ex:NumericRangeExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob, ex:Alice, ex:Ted ;
    #   	sh:property [
    #   		sh:path ex:age ;
    #   		sh:minInclusive 0 ;
    #   		sh:maxInclusive 150 ;
    #   	] .
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_maxExclusive(term, node, path, value_nodes, **options)
      compare(:<, term, node, path, value_nodes,
              RDF::Vocab::SHACL.MaxExclusiveConstraintComponent, **options)
    end

    # Compares value nodes to be <= than the specified value.
    #
    # @example
    #   ex:NumericRangeExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob, ex:Alice, ex:Ted ;
    #   	sh:property [
    #   		sh:path ex:age ;
    #   		sh:minInclusive 0 ;
    #   		sh:maxInclusive 150 ;
    #   	] .
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_maxInclusive(term, node, path, value_nodes, **options)
      compare(:<=, term, node, path, value_nodes,
              RDF::Vocab::SHACL.MaxInclusiveConstraintComponent, **options)
    end

    # Specifies the maximum string length of each value node that satisfies the condition. This can be applied to any literals and IRIs, but not to blank nodes.
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_maxLength(term, node, path, value_nodes, **options)
      term = term.first if term.is_a?(Array)
      value_nodes.map do |n|
        compares = !n.node? && n.to_s.length <= term.to_i
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless compares} a literal at with length <= #{term.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless compares),
          component: RDF::Vocab::SHACL.MaxLengthConstraintComponent,
          **options)
      end.flatten.compact
    end

    # Compares value nodes to be > than the specified value.
    #
    # @example
    #   ex:NumericRangeExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob, ex:Alice, ex:Ted ;
    #   	sh:property [
    #   		sh:path ex:age ;
    #   		sh:minInclusive 0 ;
    #   		sh:maxInclusive 150 ;
    #   	] .
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_minExclusive(term, node, path, value_nodes, **options)
      compare(:>, term, node, path, value_nodes,
              RDF::Vocab::SHACL.MinExclusiveConstraintComponent, **options)
    end

    # Compares value nodes to be >= than the specified value.
    #
    # @example
    #   ex:NumericRangeExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob, ex:Alice, ex:Ted ;
    #   	sh:property [
    #   		sh:path ex:age ;
    #   		sh:minInclusive 0 ;
    #   		sh:maxInclusive 150 ;
    #   	] .
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_minInclusive(term, node, path, value_nodes, **options)
      compare(:>=, term, node, path, value_nodes,
              RDF::Vocab::SHACL.MinInclusiveConstraintComponent, **options)
    end

    # Specifies the minimum string length of each value node that satisfies the condition. This can be applied to any literals and IRIs, but not to blank nodes.
    #
    # @param [RDF::URI] term the term is used to compare each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_minLength(term, node, path, value_nodes, **options)
      term = term.first if term.is_a?(Array)
      value_nodes.map do |n|
        compares = !n.node? && n.to_s.length >= term.to_i
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless compares} a literal with length >= #{term.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless compares),
          component: RDF::Vocab::SHACL.MinLengthConstraintComponent,
          **options)
      end.flatten.compact
    end

    # The matrix of comparisons of different types of nodes
    # @return {Hash{Class => RDF::URI}}
    NODE_KIND_COMPARE = {
      RDF::URI => [
        RDF::Vocab::SHACL.IRI,
        RDF::Vocab::SHACL.BlankNodeOrIRI,
        RDF::Vocab::SHACL.IRIOrLiteral,
      ],
      RDF::Node => [
        RDF::Vocab::SHACL.BlankNode,
        RDF::Vocab::SHACL.BlankNodeOrIRI,
        RDF::Vocab::SHACL.BlankNodeOrLiteral,
      ],
      RDF::Literal => [
        RDF::Vocab::SHACL.Literal,
        RDF::Vocab::SHACL.IRIOrLiteral,
        RDF::Vocab::SHACL.BlankNodeOrLiteral,
      ]
    }

    # Specifies a condition to be satisfied by the RDF node kind of each value node.
    #
    # @example
    #   ex:NodeKindExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetObjectsOf ex:knows ;
    #   	sh:nodeKind sh:IRI .
    #
    # @param [RDF::URI] term the kind of node to match each value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_nodeKind(term, node, path, value_nodes, **options)
      term = term.first if term.is_a?(Array)
      value_nodes.map do |n|
        compares = NODE_KIND_COMPARE.fetch(n.class, []).include?(term)
        satisfy(focus: node, path: path,
          value: n,
          message: "is#{' not' unless compares} a node kind match of #{term.to_sxp}",
          resultSeverity: (options.fetch(:severity) unless compares),
          component: RDF::Vocab::SHACL.NodeKindConstraintComponent,
          **options)
      end.flatten.compact
    end

  protected

    # Common comparison logic for lessThan, lessThanOrEqual, max/minInclusive/Exclusive
    def compare(method, terms, node, path, value_nodes, component, **options)
      terms = [terms] unless terms.is_a?(Array)
      value_nodes.map do |left|
        results = terms.map do |right|
          case left
          when RDF::Literal
            unless right.literal? && (
              (left.simple? && right.simple?) ||
              (left.is_a?(RDF::Literal::Numeric) && right.is_a?(RDF::Literal::Numeric)) ||
              (left.datatype == right.datatype && left.language == right.language))
              :incomperable
            else
              left.send(method, right)
            end
          when RDF::URI
            right.uri? && left.send(method, right)
          else
            :incomperable
          end
        end

        if results.include?(:incomperable)
          not_satisfied(focus: node, path: path,
            value: left,
            message: "is incomperable with #{terms.to_sxp}",
            resultSeverity: options.fetch(:severity),
            component: component,
            **options)
        elsif results.include?(false)
          not_satisfied(focus: node, path: path,
            value: left,
            message: "is not #{method} than #{terms.to_sxp}",
            resultSeverity: options.fetch(:severity),
            component: component,
            **options)
        else
          satisfy(focus: node, path: path,
            value: left,
            message: "is #{method} than #{terms.to_sxp}",
            component: component,
            **options)
        end
      end.flatten.compact
    end
  end
end
