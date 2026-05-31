require 'sparql/algebra'
require 'shacl/validation_result'
require 'json/ld'

module SHACL::Algebra

  ##
  # The SHACL operator.
  #
  # @abstract
  class Operator < SPARQL::Algebra::Operator
    include RDF::Util::Logger
    extend JSON::LD::Utils

    # All keys associated with shapes which are set in options
    #
    # @return [Array<Symbol>]
    BUILTIN_KEYS = %i(
      id type label name comment description deactivated severity
      message
      order group defaultValue path
      targetNode targetClass targetSubjectsOf targetObjectsOf
      class datatype nodeKind
      minCount maxCount
      minExclusive minInclusive maxExclusive maxInclusive
      minLength maxLength
      languageIn uniqueLang
      equals disjoint lessThan lessThanOrEquals
      closed ignoredProperties hasValue in
      declare namespace prefix
    ).freeze

    # Initialization options
    attr_accessor :options

    # Graph against which shapes are validated.
    # @return [RDF::Queryable]
    attr_accessor :graph

    # Graph from which original shapes were loaded.
    # @return [RDF::Graph]
    attr_accessor :shapes_graph
    # Parameters to components.
    PARAMETERS = {
      and: {class: :AndConstraintComponent},
      class: {
        class: :ClassConstraintComponent,
        nodeKind: :IRI,
      },
      closed: {
        class: :ClosedConstraintComponent,
        datatype: RDF::XSD.boolean,
      },
      datatype: {
        class: :DatatypeConstraintComponent,
        nodeKind: :IRI,
        maxCount: 1,
      },
      disjoint: {
        class: :DisjointConstraintComponent,
        nodeKind: :IRI,
      },
      equals: {
        class: :EqualsConstraintComponent,
        nodeKind: :IRI,
      },
      expression: {class: :ExpressionConstraintComponent},
      flags: {
        class: :PatternConstraintComponent,
        datatype: RDF::XSD.string,
        optional: true
      },
      hasValue: {
        class: :HasValueConstraintComponent,
        nodeKind: :IRIOrLiteral,
      },
      ignoredProperties: {
        class: :ClosedConstraintComponent,
        nodeKind: :IRI, # Added
        optional: true,
      },
      in: {
        class: :InConstraintComponent,
        nodeKind: :IRIOrLiteral,
        #maxCount: 1, # List internalized
      },
      languageIn: {
        class: :LanguageInConstraintComponent,
        datatype: RDF::XSD.string,  # Added
        #maxCount: 1, # List internalized
      },
      lessThan: {
        class: :LessThanConstraintComponent,
        nodeKind: :IRI,
      },
      lessThanOrEquals: {
        class: :LessThanOrEqualsConstraintComponent,
        nodeKind: :IRI,
      },
      maxCount: {
        class: :MaxCountConstraintComponent,
        datatype: RDF::XSD.integer,
        maxCount: 1,
      },
      maxExclusive: {
        class: :MaxExclusiveConstraintComponent,
        maxCount: 1,
        nodeKind: :Literal,
      },
      maxInclusive: {
        class: :MaxInclusiveConstraintComponent,
        maxCount: 1,
        nodeKind: :Literal,
      },
      maxLength: {
        class: :MaxLengthConstraintComponent,
        datatype: RDF::XSD.integer,
        maxCount: 1,
      },
      minCount: {
        class: :MinCountConstraintComponent,
        datatype: RDF::XSD.integer,
        maxCount: 1,
      },
      minExclusive: {
        class: :MinExclusiveConstraintComponent,
        maxCount: 1,
        nodeKind: :Literal,
      },
      minInclusive: {
        class: :MinInclusiveConstraintComponent,
        maxCount: 1,
        nodeKind: :Literal,
      },
      minLength: {
        class: :MinLengthConstraintComponent,
        datatype: RDF::XSD.integer,
        maxCount: 1,
      },
      node: {class: :NodeConstraintComponent},
      nodeKind: {
        class: :NodeKindConstraintComponent,
        in: %i(BlankNode IRI Literal BlankNodeOrIRI BlankNodeOrLiteral IRIOrLiteral),
        maxCount: 1,
      },
      not: {class: :NotConstraintComponent},
      or: {class: :OrConstraintComponent},
      pattern: {
        class: :PatternConstraintComponent,
        datatype: RDF::XSD.string,
      },
      property: {class: :PropertyConstraintComponent},
      qualifiedMaxCount: {
        class: :QualifiedMaxCountConstraintComponent,
        datatype: RDF::XSD.integer,
      },
      qualifiedValueShape: {
        class: %i(QualifiedMaxCountConstraintComponent QualifiedMinCountConstraintComponent),
      },
      qualifiedValueShapesDisjoint: {
        class: %i(QualifiedMaxCountConstraintComponent QualifiedMinCountConstraintComponent),
        datatype: RDF::XSD.boolean,
        optional: true,
      },
      qualifiedMinCount: {
        class: :QualifiedMinCountConstraintComponent,
        datatype: RDF::XSD.integer
      },
      sparql: {class: :SPARQLConstraintComponent},
      uniqueLang: {
        class: :UniqueLangConstraintComponent,
        datatype: RDF::XSD.boolean,
        maxCount: 1,
      },
      xone: {class: :XoneConstraintComponent},
    }

    # Constraint Component classes indexed to their mandatory and optional parameters.
    #
    # @note for builtins, corresponding Ruby classes may not exist.
    COMPONENT_PARAMS = PARAMETERS.inject({}) do |memo, (param, properties)|
      memo.merge(Array(properties[:class]).inject(memo) do |mem, cls|
        entry = mem.fetch(cls, {})
        param_type = properties[:optional] ? :optional : :mandatory
        entry[param_type] ||= []
        entry[param_type] << param
        mem.merge(cls => entry)
      end)
    end

    ## Class methods
    class << self
      ##
      # Creates an operator instance from a parsed SHACL representation
      # @param [Hash] operator
      # @param [Hash] options ({})
      # @option options [Hash{String => RDF::URI}] :prefixes
      # @return [Operator]
      def from_json(operator, **options)
        operands = []

        # Node options used to instantiate the relevant class instance.
        node_opts = options.dup

        # Node Options and operands on shape or node, which are not Constraint Component Parameters
        operator.each do |k, v|
          k = k.to_sym
          next if v.nil? || PARAMETERS.include?(k)
          case k
          # List properties
          when :id                 then node_opts[:id] = iri(v, vocab: false, **options)
          when :path               then node_opts[:path] = parse_path(v, **options)
          when :property
            operands.push(*as_array(v).map {|vv| PropertyShape.from_json(vv, **options)})
          when :severity           then node_opts[:severity] = iri(v, **options)
          when :targetClass        then node_opts[:targetClass] = as_array(v).map {|vv| iri(vv, **options)}
          when :targetNode
            node_opts[:targetNode] = as_array(v).map do |vv|
              from_expanded_value(vv, **options)
            end
          when :targetObjectsOf    then node_opts[:targetObjectsOf] = as_array(v).map {|vv| iri(vv, **options)}
          when :targetSubjectsOf   then node_opts[:targetSubjectsOf] = as_array(v).map {|vv| iri(vv, **options)}
          when :type               then node_opts[:type] = as_array(v).map {|vv| iri(vv, **options)}
          else
            if BUILTIN_KEYS.include?(k)
              # Add as a plain option otherwise
              node_opts[k] = to_rdf(k, v, **options)
            end
          end
        end

        # Node Options and operands on shape or node, which are Constraint Component Parameters.
        # For constraints with a defined Ruby class, the primary parameter is the NAME from the constraint class. Other parameters are added as named operands to the component operator.
        used_components = {}
        operator.each do |k, v|
          k = k.to_sym
          next if v.nil? || !PARAMETERS.include?(k)
          param_props = PARAMETERS[k]
          param_classes = Array(param_props[:class])

          # Keep track of components which have been used.
          param_classes.each {|cls| used_components[cls] ||= {}}

          # Check parameter constraints
          v = as_array(v)
          if param_props[:maxCount] && v.length > param_props[:maxCount]
            raise SHACL::Error, "Property #{k} on #{self.const_get(:NAME)} has too many values: #{v.inspect}"
          end

          # If an optional parameter exists without corresponding mandatory parameters on a given shape, raise a SHACL::Error.
          #
          # Records any instances of components which are created to re-attach non-primary parameters after all operators are processed.
          instances = case k
          # List properties
          when :node
            as_array(v).map {|vv| NodeShape.from_json(vv, **options)}
          when :property
            as_array(v).map {|vv| PropertyShape.from_json(vv, **options)}
          when :sparql
            as_array(v).map {|vv| SPARQLConstraintComponent.from_json(vv, **options)}
          else
            # Process parameter values based on nodeKind, in, and datatype.
            elements = if param_props[:nodeKind]
              case param_props[:nodeKind]
              when :IRI
                v.map {|vv| iri(vv, **options)}
              when :Literal
                v.map do |vv|
                  vv.is_a?(Hash) ?
                    from_expanded_value(vv, **options) :
                    RDF::Literal(vv)
                end
              when :IRIOrLiteral
                to_rdf(k, v, **options)
              end
            elsif param_props[:in]
              v.map do |vv|
                iri(vv, **options) if param_props[:in].include?(vv.to_sym)
              end
            elsif param_props[:datatype]
              v.map {|vv| RDF::Literal(vv, datatype: param_props[:datatype])}
            else
              v.map {|vv| SHACL::Algebra.from_json(vv, **options)}
            end

            # Builtins are added as options to the operator, otherwise, they are class instances of constraint components added as operators.
            if BUILTIN_KEYS.include?(k)
              node_opts[k] = elements
              [] # No instances created
            else
              klass = SHACL::Algebra.const_get(Array(param_props[:class]).first)

              name = klass.const_get(:NAME)
              # If the key `k` is the same as the NAME of the class, create the instance with the defined element values.
              if name == k
                elements.map {|e| klass.new(*e, **options.dup)}
              else
                # Add non-primary parameters for subsequent insertion
                param_classes.each do |cls|
                  (used_components[cls][:parameters] ||= []) << elements.unshift(k)
                end
                [] # No instances created
              end
            end
          end

          # Record the instances created by class and add as operands
          param_classes.each do |cls|
            used_components[cls][:instances] = instances
          end
          operands.push(*instances)
        end

        # Append any parameters to the used components
        used_components.each do |cls, props|
          instances = props[:instances]
          next unless instances # BUILTINs

          parameters = props.fetch(:parameters, [])
          instances.each do |op|
            parameters.each do |param|
              # Note the potential that the parameter gets added twice, if there are multiple classes for both the primary and secondary paramters.
              op.operands << param
            end
          end
        end

        new(*operands, **node_opts)
      end

      # Create URIs
      # @param  (see #iri)
      # @option (see #iri)
      # @return (see #iri)
      def iri(value, base: RDF::Vocab::SHACL.to_uri, vocab: true, **options)
        # Context will have been pre-loaded
        @context ||= JSON::LD::Context.parse("http://github.com/ruby-rdf/shacl/")

        value = value['id'] || value['@id'] if value.is_a?(Hash)
        result = @context.expand_iri(value, base: base, vocab: vocab)
        result = RDF::URI(result) if result.is_a?(String)
        if result.respond_to?(:qname) && result.qname
          result = RDF::URI.new(result.to_s) if result.frozen?
          result.lexical = result.qname.join(':')
        end
        result
      end

      # Turn a JSON-LD value into its RDF representation
      # @see JSON::LD::ToRDF.item_to_rdf
      # @param [Symbol] term
      # @param [Object] item
      # @return RDF::Term
      def to_rdf(term, item, **options)
        @context ||= JSON::LD::Context.parse("http://github.com/ruby-rdf/shacl/")

        return item.map {|v| to_rdf(term, v, **options)} if item.is_a?(Array)

        case
        when item.is_a?(TrueClass) || item.is_a?(FalseClass) || item.is_a?(Numeric)
          return RDF::Literal(item)
        when value?(item)
          value, datatype = item.fetch('@value'), item.fetch('type', nil)
          case value
          when TrueClass, FalseClass, Numeric
            return RDF::Literal(value)
          else
            datatype ||= item.has_key?('@direction') ?
              RDF::URI("https://www.w3.org/ns/i18n##{item.fetch('@language', '').downcase}_#{item['@direction']}") :
              (item.has_key?('@language') ? RDF.langString : RDF::XSD.string)
          end
          datatype = iri(datatype) if datatype
                  
          # Initialize literal as an RDF literal using value and datatype. If element has the key @language and datatype is xsd:string, then add the value associated with the @language key as the language of the object.
          language = item.fetch('@language', nil) if datatype == RDF.langString
          return RDF::Literal.new(value, datatype: datatype, language: language)
        when node?(item)
          return iri(item, **options)
        when list?(item)
          RDF::List(*item['@list'].map {|v| to_rdf(term, v, **options)})
        when item.is_a?(String)
          RDF::Literal(item)
        else
          raise "Can't transform #{item.inspect} to RDF on property #{term}"
        end
      end

      # Interpret a JSON-LD expanded value
      # @param [Hash] item
      # @return [RDF::Term]
      def from_expanded_value(item, **options)
        if item['@value']
          value, datatype = item.fetch('@value'), item.fetch('type', nil)
          case value
          when TrueClass, FalseClass
            value = value.to_s
            datatype ||= RDF::XSD.boolean.to_s
          when Numeric
            # Don't serialize as double if there are no fractional bits
            as_double = value.ceil != value || value >= 1e21 || datatype == RDF::XSD.double
            lit = if as_double
              RDF::Literal::Double.new(value, canonicalize: true)
            else
              RDF::Literal.new(value.numerator, canonicalize: true)
            end

            datatype ||= lit.datatype
            value = lit.to_s.sub("E+", "E")
          else
            datatype ||= item.has_key?('@language') ? RDF.langString : RDF::XSD.string
          end
          datatype = iri(datatype) if datatype
          language = item.fetch('@language', nil) if datatype == RDF.langString
          RDF::Literal.new(value, datatype: datatype, language: language)
        elsif item['id']
          self.iri(item['id'], **options)
        else
          RDF::Node.new
        end
      end

      ##
      # Parse the "path" attribute into a SPARQL Property Path and evaluate to find related nodes.
      #
      # @param [Object] path
      # @return [RDF::URI, SPARQL::Algebra::Expression]
      def parse_path(path, **options)
        case path
        when RDF::URI then path
        when String then iri(path)
        when Hash
          # Creates a SPARQL S-Expression resulting in a query which can be used to find corresponding
          {
            alternativePath: :alt,
            inversePath: :reverse,
            oneOrMorePath: :"path+",
            "@list": :seq,
            zeroOrMorePath: :"path*",
            zeroOrOnePath: :"path?",
          }.each do |prop, op_sym|
            if path[prop.to_s]
              value = path[prop.to_s]
              value = value['@list'] if value.is_a?(Hash) && value.key?('@list')
              value = [value] if !value.is_a?(Array)
              value = value.map {|e| parse_path(e, **options)}
              op = SPARQL::Algebra::Operator.for(op_sym)
              if value.length > op.arity
                # Divide into the first operand followed by the operator re-applied to the reamining operands
                value = value.first, apply_op(op, value[1..-1])
              end
              return op.new(*value)
            end
          end

          if path['id']
            iri(path['id'])
          else
            log_error('PropertyPath', "Can't handle path", **options) {path.to_sxp}
          end
        else
          log_error('PropertyPath', "Can't handle path", **options) {path.to_sxp}
        end
      end

      # Recursively apply operand to sucessive values until the argument count which is expected is achieved
      def apply_op(op, values)
        if values.length > op.arity
          values = values.first, apply_op(op, values[1..-1])
        end
        op.new(*values)
      end
      protected :apply_op
    end

    # The ID of this operator
    # @return [RDF::Resource]
    def id; @options[:id]; end

    # The types associated with this operator
    # @return [Array<RDF::URI>]
    def type; @options[:type]; end

    # Any label associated with this operator
    # @return [RDF::Literal]
    def label; @options[:label]; end

    # Is this shape deactivated?
    # @return [Boolean]
    def deactivated?; @options[:deactivated] == RDF::Literal::TRUE; end

    # Any comment associated with this operator
    # @return [RDF::Literal]
    def comment; @options[:comment]; end

    # Create URIs
    # @param [RDF::Value, String] value
    # @param [RDF::URI] base Base IRI used for resolving relative values (RDF::Vocab::SHACL.to_uri).
    # @param [Boolean] vocab resolve vocabulary relative to the builtin context.
    # @param [Hash{Symbol => Object}] options
    # @return [RDF::Value]
    def iri(value, base: RDF::Vocab::SHACL.to_uri, vocab: true, **options)
      self.class.iri(value, base: base, vocab: vocab, **options)
    end

    # Validates the specified `node` within `graph`, a list of {ValidationResult}.
    #
    # A node conforms if it is not deactivated and all of its operands conform.
    #
    # @param [RDF::Term] node
    # @param [Hash{Symbol => Object}] options
    # @return [Array<ValidationResult>]
    def conforms(node, depth: 0, **options)
      raise NotImplemented
    end

    # Create structure for serializing this component/shape, beginning with its cononical name.
    def to_sxp_bin
      expressions = BUILTIN_KEYS.inject([self.class.const_get(:NAME)]) do |memo, sym|
        @options[sym] ? memo.push([sym, *@options[sym]]) : memo
      end + operands

      expressions.to_sxp_bin
    end

    ##
    # Create a result that satisfies the shape.
    #
    # @param [RDF::Term] focus
    # @param [RDF::Resource] shape
    # @param [RDF::URI] component
    # @param [RDF::URI] resultSeverity (nil)
    # @param [Array<RDF::URI>] path (nil)
    # @param [RDF::Term] value (nil)
    # @param [RDF::Term] details (nil)
    # @param [String] message (nil)
    # @return [Array<SHACL::ValidationResult>]
    def satisfy(focus:, shape:, component:, resultSeverity: nil, path: nil, value: nil, details: nil, message: nil, **options)
      log_debug(self.class.const_get(:NAME), "#{'not ' if resultSeverity}satisfied #{value.to_sxp if value}#{': ' + message if message}", **options)
      [SHACL::ValidationResult.new(focus, path, shape, resultSeverity, component,
                                   details, value, message)]
    end

    ##
    # Create a result that does not satisfies the shape.
    #
    # @param [RDF::Term] focus
    # @param [RDF::Resource] shape
    # @param [RDF::URI] component
    # @param [RDF::URI] resultSeverity (RDF:::Vocab::SHACL.Violation)
    # @param [Array<RDF::URI>] path (nil)
    # @param [RDF::Term] value (nil)
    # @param [RDF::Term] details (nil)
    # @param [String] message (nil)
    # @return [Array<SHACL::ValidationResult>]
    def not_satisfied(focus:, shape:, component:, resultSeverity: RDF::Vocab::SHACL.Violation, path: nil, value: nil, details: nil, message: nil, **options)
      log_info(self.class.const_get(:NAME), "not satisfied #{value.to_sxp if value}#{': ' + message if message}", **options)
      [SHACL::ValidationResult.new(focus, path, shape, resultSeverity, component,
                                   details, value, message)]
    end
  end
end
