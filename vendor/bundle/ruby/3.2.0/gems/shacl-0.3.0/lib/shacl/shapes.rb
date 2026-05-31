require_relative 'algebra'
require_relative 'validation_report'
require_relative 'context'
require 'json/ld'

module SHACL
  ##
  # The set of shapes loaded from a graph.
  class Shapes < Array
    include RDF::Util::Logger

    # The original shapes graph
    #
    # @return [RDF::Graph]
    attr_reader :shapes_graph


    # The graphs which have been loaded as shapes
    #
    # @return [Array<RDF::URI>]
    attr_reader :loaded_graphs

    # The JSON used to instantiate shapes
    #
    # @return [Array<Hash>]
    attr_reader :shape_json

    ##
    # Initializes the shapes from `graph`loading `owl:imports` until all references are loaded.
    #
    # The shapes come from the following:
    # * Instances of `sh:NodeShape` or `sh:PropertyShape`
    # * resources that have any of the properties `sh:targetClass`, `sh:targetNode`, `sh:targetObjectsOf`, or `sh:targetSubjectsOf`.
    #
    # @param [RDF::Graph] graph
    # @param [Array<RDF::URI>] loaded_graphs = []
    #   The graphs which have been loaded as shapes
    # @param [Hash{Symbol => Object}] options
    # @return [Shapes]
    # @raise [SHACL::Error]
    def self.from_graph(graph, loaded_graphs: [], **options)
      @loded_graphs = loaded_graphs

      import_count = 0
      while (imports = graph.query({predicate: RDF::OWL.imports}).map(&:object)).count > import_count
        # Load each imported graph
        imports.each do |ref|
          # Don't try import if the import subject is already in the graph
          unless graph.subject?(ref)
            begin
              options[:logger].info('Shapes') {"load import #{ref}"} if options[:logger].respond_to?(:info)
              graph.load(ref)
              loaded_graphs << ref
            rescue IOError => e
              # Skip import
              options[:logger].warn('Shapes') {"load import #{ref}"} if options[:logger].respond_to?(:warn)
            end
          end
          import_count += 1
        end
      end

      # Serialize the graph as framed JSON-LD and initialize patterns, recursively.
      shape_json = JSON::LD::API.fromRdf(graph, useNativeTypes: true) do |expanded|
        JSON::LD::API.frame(expanded, SHAPES_FRAME, omitGraph: false, embed: '@always', expanded: true)
      end['@graph']

      # Create an array of the framed shapes
      shapes = self.new(shape_json.map {|o| Algebra.from_json(o, **options)})
      shapes.instance_variable_set(:@shape_json, shape_json)
      shapes.instance_variable_set(:@shapes_graph, graph)
      shapes
    end

    ##
    # Retrieve shapes from a sh:shapesGraph reference within the queryable
    #
    # @param [RDF::Queryable] queryable
    #   The data graph which may contain references to the shapes graph
    # @param [Hash{Symbol => Object}] options
    # @return [Shapes]
    # @raise [SHACL::Error]
    def self.from_queryable(queryable, **options)
      # Query queryable to find one ore more shapes graphs
      graph_names = queryable.query({predicate: RDF::Vocab::SHACL.shapesGraph}).objects
      graph = RDF::Graph.new(graph_name: graph_names.first, data: RDF::Repository.new) do |g|
        graph_names.each {|iri| g.load(iri, graph_name: graph_names.first)}
      end
      from_graph(graph, loaded_graphs: graph_names, **options)
    end

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Queryable] graph
    # @return [Hash{RDF::Term => Array<ValidationResult>}] Returns _ValidationResults_, a hash of focus nodes to the results of their associated shapes
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::Term] :focus
    #   An explicit focus node, overriding any defined on the top-level shaps.
    # @option options [Logger, #write, #<<] :logger
    #   Record error/info/debug output
    # @return [SHACL::ValidationReport]
    def execute(graph, depth: 0, **options)
      self.each do |shape|
        shape.graph = graph
        shape.shapes_graph = shapes_graph
        shape.each_descendant do |op|
          op.instance_variable_set(:@logger, options[:logger]) if
            options[:logger] && op.respond_to?(:execute)
          op.graph = graph if op.respond_to?(:graph=)
          op.shapes_graph = shapes_graph if op.respond_to?(:shapes_graph=)
        end
      end

      # Execute all shapes against their target nodes
      ValidationReport.new(self.map do |shape|
        nodes = Array(options.fetch(:focus, shape.targetNodes))
        nodes.map do |node|
          shape.conforms(node, depth: depth + 1)
        end
      end.flatten)
    end

    def to_sxp_bin
      [:shapes, super]
    end

    ##
    # Transform Shapes into an SXP.
    #
    # @return [String]
    def to_sxp(**options)
      to_sxp_bin.to_sxp(**options)
    end

    SHAPES_FRAME = JSON.parse(%({
      "@context": {
        "id": "@id",
        "type": {"@id": "@type", "@container": "@set"},
        "@vocab": "http://www.w3.org/ns/shacl#",
        "owl": "http://www.w3.org/2002/07/owl#",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
        "shacl": "http://www.w3.org/ns/shacl#",
        "sh": "http://www.w3.org/ns/shacl#",
        "xsd": "http://www.w3.org/2001/XMLSchema#",
        "and": {"@type": "@id"},
        "annotationProperty": {"@type": "@id"},
        "class": {"@type": "@id"},
        "comment": "http://www.w3.org/2000/01/rdf-schema#comment",
        "condition": {"@type": "@id"},
        "datatype": {"@type": "@vocab"},
        "declare": {"@type": "@id"},
        "disjoint": {"@type": "@id"},
        "entailment": {"@type": "@id"},
        "equals": {"@type": "@id"},
        "ignoredProperties": {"@type": "@id", "@container": "@list"},
        "imports": {"@id": "owl:imports", "@type": "@id"},
        "in": {"@type": "@none", "@container": "@list"},
        "inversePath": {"@type": "@id"},
        "label": "http://www.w3.org/2000/01/rdf-schema#label",
        "languageIn": {"@container": "@list"},
        "lessThan": {"@type": "@id"},
        "lessThanOrEquals": {"@type": "@id"},
        "namespace": {"@type": "xsd:anyURI"},
        "nodeKind": {"@type": "@vocab"},
        "or": {"@type": "@id"},
        "path": {"@type": "@none"},
        "prefixes": {"@type": "@id"},
        "property": {"@type": "@id"},
        "severity": {"@type": "@vocab"},
        "sparql": {"@type": "@id"},
        "targetClass": {"@type": "@id"},
        "targetNode": {"@type": "@none"},
        "xone": {"@type": "@id"}
      },
      "and": {},
      "class": {},
      "datatype": {},
      "in": {"@embed": "@never"},
      "node": {},
      "nodeKind": {},
      "not": {},
      "or": {},
      "property": {},
      "sparql": {},
      "targetClass": {},
      "targetNode": {},
      "targetObjectsOf": {},
      "xone": {},
      "targetSubjectsOf": {}
    })).freeze
  end
end
