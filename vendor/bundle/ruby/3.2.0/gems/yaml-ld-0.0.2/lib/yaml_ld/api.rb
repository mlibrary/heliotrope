# -*- encoding: utf-8 -*-
# frozen_string_literal: true
require 'json/ld/api'

module YAML_LD
  ##
  # A YAML-LD processor based on JSON-LD.
  #
  # @see https://www.w3.org/TR/json-ld11-api/#the-application-programming-interface
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  class API < ::JSON::LD::API
    # The following constants are used to reduce object allocations
    LINK_REL_CONTEXT = %w(rel http://www.w3.org/ns/yaml-ld#context).freeze
    LINK_REL_ALTERNATE = %w(rel alternate).freeze
    LINK_TYPE_JSONLD = %w(type application/ld+yaml).freeze

    ##
    # Expands the given input according to the steps in the Expansion Algorithm. The input must be copied, expanded and returned if there are no errors. If the expansion fails, an appropriate exception must be thrown.
    #
    # The resulting `Array` either returned or yielded
    #
    # @param [String, #read, Hash, Array] input
    #   The YAML-LD object to copy and perform the expansion upon.
    # @param [Proc] documentLoader
    #   The callback of the loader to be used to retrieve remote documents and contexts, and to parse IO objects.
    #   If specified, it must be used to retrieve remote documents and contexts; otherwise, if not specified, the processor's built-in loader must be used. See {documentLoader} for the method signature.
    #   The remote document returned must be parsed if it is YAML.
    # @param [Proc] serializer (nil)
    #   A Serializer method used for generating the YAML serialization of the result. If absent, the internal Ruby objects are returned, which can be transformed to YAML externally via `#to_yaml`.
    #   See {YAML_LD::API.serializer}.
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI, String, #to_s] :base
    #   The Base IRI to use when expanding the document. This overrides the value of `input` if it is a _IRI_. If not specified and `input` is not an _IRI_, the base IRI defaults to the current document IRI if in a browser context, or the empty string if there is no document context. If not specified, and a base IRI is found from `input`, options[:base] will be modified with this value.
    # @option options [Boolean] :compactArrays (true)
    #   If set to `true`, the JSON-LD processor replaces arrays with just one element with that element during compaction. If set to `false`, all arrays will remain arrays even if they have just one element.
    # @option options [Boolean] :compactToRelative (true)
    #   Creates document relative IRIs when compacting, if `true`, otherwise leaves expanded.
    # @option options [Proc] :documentLoader
    #   The callback of the loader to be used to retrieve remote documents and contexts. If specified, it must be used to retrieve remote documents and contexts; otherwise, if not specified, the processor's built-in loader must be used. See {documentLoader} for the method signature.
    # @option options [String, #read, Hash, Array, JSON::LD::Context] :expandContext
    #   A context that is used to initialize the active context when expanding a document.
    # @option options [Boolean] :extendedYAML (false)
    #   Use the expanded internal representation.
    # @option options [Boolean] :extractAllScripts
    #   If set, when given an HTML input without a fragment identifier, extracts all `script` elements with type `application/ld+json` into an array during expansion.
    # @option options [Boolean, String, RDF::URI] :flatten
    #   If set to a value that is not `false`, the JSON-LD processor must modify the output of the Compaction Algorithm or the Expansion Algorithm by coalescing all properties associated with each subject via the Flattening Algorithm. The value of `flatten must` be either an _IRI_ value representing the name of the graph to flatten, or `true`. If the value is `true`, then the first graph encountered in the input document is selected and flattened.
    # @option options [String] :language
    #   When set, this has the effect of inserting a context definition with `@language` set to the associated value, creating a default language for interpreting string values.
    # @option options [Boolean] :lowercaseLanguage
    #   By default, language tags are left as is. To normalize to lowercase, set this option to `true`.
    # @option options [Boolean] :ordered (true)
    #   Order traversal of dictionary members by key when performing algorithms.
    # @option options [Boolean] :rdfstar      (false)
    #   support parsing JSON-LD-star statement resources.
    # @option options [Boolean] :rename_bnodes (true)
    #   Rename bnodes as part of expansion, or keep them the same.
    # @option options [Boolean]  :unique_bnodes   (false)
    #   Use unique bnode identifiers, defaults to using the identifier which the node was originally initialized with (if any).
    # @option options [Boolean] :validate Validate input, if a string or readable object.
    # @raise [JsonLdError]
    # @yield YAML_LD, base_iri
    # @yieldparam [Array<Hash>] yamlld
    #   The expanded YAML-LD document
    # @yieldparam [RDF::URI
    #   The document base as determined during expansion
    # @yieldreturn [String] returned YAML serialization
    # @return [String]
    #   If a block is given, the result of evaluating the block is returned, otherwise, the expanded YAML-LD document
    # @see https://www.w3.org/TR/json-ld11-api/#expansion-algorithm
    def self.expand(input,
                    documentLoader: self.method(:documentLoader),
                    serializer: self.method(:serializer),
                    **options,
                    &block)
      JSON::LD::API.expand(input,
                           allowed_content_types: %r(application/(.+\+)?yaml),
                           documentLoader: documentLoader, 
                           extendedRepresentation: options[:extendedYAML],
                           processingMode: 'json-ld-1.1',
                           serializer: serializer,
                           **options,
                           &block)
    end

    ##
    # Compacts the given input according to the steps in the Compaction Algorithm. The input must be copied, compacted and returned if there are no errors. If the compaction fails, an appropirate exception must be thrown.
    #
    # If no context is provided, the input document is compacted using the top-level context of the document
    #
    # The resulting `Hash` is either returned or yielded, if a block is given.
    #
    # @param [String, #read, Hash, Array] input
    #   The YAML-LD object to copy and perform the expansion upon.
    # @param [String, #read, Hash, Array, JSON::LD::Context] context
    #   The base context to use when compacting the input.
    # @param [Proc] serializer (nil)
    #   A Serializer method used for generating the YAML serialization of the result. If absent, the internal Ruby objects are returned, which can be transformed to YAML externally via `#to_yaml`.
    #   See {YAML_LD::API.serializer}.
    # @param [Boolean] expanded (false) Input is already expanded
    # @param  [Hash{Symbol => Object}] options
    # @option options (see expand)
    # @yield YAML_LD
    # @yieldparam [Array<Hash>] yamlld
    #   The expanded YAML-LD document
    # @yieldreturn [String] returned YAML serialization
    # @return [String]
    #   If a block is given, the result of evaluating the block is returned, otherwise, the expanded YAML-LD document
    # @raise [JsonLdError]
    # @see https://www.w3.org/TR/json-ld11-api/#compaction-algorithm
    def self.compact(input, context, expanded: false,
                     documentLoader: self.method(:documentLoader),
                     serializer: self.method(:serializer),
                     **options,
                     &block)
      JSON::LD::API.compact(input, context, expanded: expanded,
                           allowed_content_types: %r(application/(.+\+)?yaml),
                           documentLoader: documentLoader, 
                           extendedRepresentation: options[:extendedYAML],
                           processingMode: 'json-ld-1.1',
                           serializer: serializer,
                           **options,
                           &block)
    end

    ##
    # This algorithm flattens an expanded YAML-LD document by collecting all properties of a node in a single object and labeling all blank nodes with blank node identifiers. This resulting uniform shape of the document, may drastically simplify the code required to process YAML-LD data in certain applications.
    #
    # The resulting `Array` is either returned, or yielded if a block is given.
    #
    # @param [String, #read, Hash, Array] input
    #   The YAML-LD object or array of JSON-LD objects to flatten or an IRI referencing the JSON-LD document to flatten.
    # @param [String, #read, Hash, Array, JSON::LD::EvaluationContext] context
    #   An optional external context to use additionally to the context embedded in input when expanding the input.
    # @param [Boolean] expanded (false) Input is already expanded
    # @param [Proc] serializer (nil)
    #   A Serializer method used for generating the YAML serialization of the result. If absent, the internal Ruby objects are returned, which can be transformed to YAML externally via `#to_yaml`.
    #   See {YAML_LD::API.serializer}.
    # @param  [Hash{Symbol => Object}] options
    # @option options (see expand)
    # @option options [Boolean] :createAnnotations
    #   Unfold embedded nodes which can be represented using `@annotation`.
    # @option options [Boolean] :extendedYAML (false)
    #   Use the expanded internal representation.
    # @yield YAML_LD
    # @yieldparam [Array<Hash>] yamlld
    #   The expanded YAML-LD document
    # @yieldreturn [String] returned YAML serialization
    # @return [Object, Hash]
    #   If a block is given, the result of evaluating the block is returned, otherwise, the flattened JSON-LD document
    # @see https://www.w3.org/TR/json-ld11-api/#framing-algorithm
    def self.flatten(input, context, expanded: false,
                     documentLoader: self.method(:documentLoader),
                     serializer: self.method(:serializer),
                     **options,
                     &block)
      JSON::LD::API.flatten(input, context, expanded: expanded,
                            allowed_content_types: %r(application/(.+\+)?yaml),
                            documentLoader: documentLoader, 
                            extendedRepresentation: options[:extendedYAML],
                            processingMode: 'json-ld-1.1',
                            serializer: serializer,
                            **options,
                            &block)
    end

    ##
    # Frames the given input using the frame according to the steps in the Framing Algorithm. The input is used to build the framed output and is returned if there are no errors. If there are no matches for the frame, null must be returned. Exceptions must be thrown if there are errors.
    #
    # The resulting `Array` is either returned, or yielded if a block is given.
    #
    # @param [String, #read, Hash, Array] input
    #   The YAML-LD object or array of YAML-LD objects to flatten or an IRI referencing the JSON-LD document to flatten.
    # @param [String, #read, Hash, Array] frame
    #   The frame to use when re-arranging the data.
    # @param [Boolean] expanded (false) Input is already expanded
    # @option options (see expand)
    # @option options ['@always', '@link', '@once', '@never'] :embed ('@once')
    #   a flag specifying that objects should be directly embedded in the output, instead of being referred to by their IRI.
    # @option options [Boolean] :explicit (false)
    #   a flag specifying that for properties to be included in the output, they must be explicitly declared in the framing context.
    # @option options [Boolean] :extendedYAML (false)
    #   Use the expanded internal representation.
    # @option options [Boolean] :requireAll (false)
    #   A flag specifying that all properties present in the input frame must either have a default value or be present in the JSON-LD input for the frame to match.
    # @option options [Boolean] :omitDefault (false)
    #   a flag specifying that properties that are missing from the JSON-LD input should be omitted from the output.
    # @option options [Boolean] :pruneBlankNodeIdentifiers (true) removes blank node identifiers that are only used once.
    # @option options [Boolean] :omitGraph does not use `@graph` at top level unless necessary to describe multiple objects, defaults to `true` if processingMode is 1.1, otherwise `false`.
    # @yield YAML_LD
    # @yieldparam [Array<Hash>] yamlld
    #   The expanded YAML-LD document
    # @yieldreturn [String] returned YAML serialization
    # @return [Object, Hash]
    #   If a block is given, the result of evaluating the block is returned, otherwise, the framed JSON-LD document
    # @raise [InvalidFrame]
    # @see https://www.w3.org/TR/json-ld11-api/#framing-algorithm
    def self.frame(input, frame, expanded: false,
                   documentLoader: self.method(:documentLoader),
                   serializer: self.method(:serializer),
                   **options,
                   &block)
      JSON::LD::API.frame(input, frame, expanded: expanded,
                          allowed_content_types: %r(application/(.+\+)?yaml),
                          documentLoader: documentLoader, 
                          extendedRepresentation: options[:extendedYAML],
                          processingMode: 'json-ld-1.1',
                          serializer: serializer,
                          **options,
                          &block)
    end

    ##
    # Processes the input according to the RDF Conversion Algorithm, calling the provided callback for each triple generated.
    #
    # @param [String, #read, Hash, Array] input
    #   The YAML-LD object to process when outputting statements.
    # @param [Boolean] expanded (false) Input is already expanded
    # @option options (see expand)
    # @option options [Boolean] :extendedYAML (false)
    #   Use the expanded internal representation.
    # @option options [Boolean] :produceGeneralizedRdf (false)
    #   If true, output will include statements having blank node predicates, otherwise they are dropped.
    # @raise [JsonLdError]
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    # @return [RDF::Enumerable] set of statements, unless a block is given.
    def self.toRdf(input, expanded: false,
                   documentLoader: self.method(:documentLoader),
                   **options,
                   &block)
      JSON::LD::API.toRdf(input, expanded: expanded,
                          allowed_content_types: %r(application/(.+\+)?yaml),
                          documentLoader: documentLoader, 
                          extendedRepresentation: options[:extendedYAML],
                          processingMode: 'json-ld-1.1',
                          **options,
                          &block)
    end
    
    ##
    # Take an ordered list of RDF::Statements and turn them into a JSON-LD document.
    #
    # The resulting `Array` is either returned or yielded, if a block is given.
    #
    # @param [RDF::Enumerable] input
    # @param [Boolean] useRdfType (false)
    #   If set to `true`, the JSON-LD processor will treat `rdf:type` like a normal property instead of using `@type`.
    # @param [Boolean] useNativeTypes (false) use native representations
    # @param [Proc] serializer (nil)
    #   A Serializer method used for generating the YAML serialization of the result. If absent, the internal Ruby objects are returned, which can be transformed to YAML externally via `#to_yaml`.
    #   See {YAML_LD::API.serializer}.
    # @param  [Hash{Symbol => Object}] options
    # @option options (see expand)
    # @option options [Boolean] :extendedYAML (false)
    #   Use the expanded internal representation.
    # @yield jsonld
    # @yieldparam [Hash] jsonld
    #   The JSON-LD document in expanded form
    # @yieldreturn [Object] returned object
    # @return [Object, Hash]
    #   If a block is given, the result of evaluating the block is returned, otherwise, the expanded JSON-LD document
    def self.fromRdf(input, useRdfType: false, useNativeTypes: false,
                     documentLoader: self.method(:documentLoader),
                     serializer: self.method(:serializer),
                     **options,
                     &block)
      JSON::LD::API.fromRdf(input,
                            allowed_content_types: %r(application/(.+\+)?yaml),
                            documentLoader: documentLoader, 
                            extendedRepresentation: options[:extendedYAML],
                            processingMode: 'json-ld-1.1',
                            serializer: serializer,
                            useRdfType: useRdfType,
                            useNativeTypes: useNativeTypes,
                            **options,
                            &block)
    end

    ##
    # Default document loader for YAML_LD.
    # @param [RDF::URI, String] url
    # @param [Boolean] extractAllScripts
    #   If set to `true`, when extracting JSON-LD script elements from HTML, unless a specific fragment identifier is targeted, extracts all encountered JSON-LD script elements using an array form, if necessary.
    # @param [String] profile
    #   When the resulting `contentType` is `text/html` or `application/xhtml+xml`, this option determines the profile to use for selecting a JSON-LD script elements.
    # @param [String] requestProfile
    #   One or more IRIs to use in the request as a profile parameter.
    # @param [Hash<Symbol => Object>] options
    # @yield remote_document
    # @yieldparam [RemoteDocument, RDF::Util::File::RemoteDocument] remote_document
    # @raise [IOError]
    def self.documentLoader(url, extractAllScripts: false, profile: nil, requestProfile: nil, **options, &block)
      if url.respond_to?(:read)
        base_uri = options[:base]
        base_uri ||= url.base_uri if url.respond_to?(:base_uri)
        content_type = options[:content_type]
        content_type ||= url.content_type if url.respond_to?(:content_type)
        context_url = if url.respond_to?(:links) && url.links &&
          # Any JSON type other than ld+json
          (content_type == 'application/json' || content_type.match?(%r(application/(^ld)+json)))
          link = url.links.find_link(JSON::LD::API::LINK_REL_CONTEXT)
          link.href if link
        elsif  url.respond_to?(:links) && url.links &&
          # Any YAML type
          content_type.match?(%r(application/(\w+\+)*yaml))
          link = url.links.find_link(LINK_REL_CONTEXT)
          link.href if link
        end

        content = case content_type
        when nil, %r(application/(\w+\+)*yaml)
          # Parse YAML
          Representation.load(url.read, filename: url.to_s, **options)
        else
          url.read
        end
        block.call(RemoteDocument.new(content,
          documentUrl: base_uri,
          contentType: content_type,
          contextUrl: context_url))
      elsif url.to_s.match?(/\.yaml\w*$/) || content_type.to_s.match?(%r(application/(\w+\+)*yaml))
        # Parse YAML
        content = Representation.load(RDF::Util::File.open_file(url.to_s).read,
                                             filename: url.to_s,
                                             **options)

        block.call(RemoteDocument.new(content,
          documentUrl: base_uri,
          contentType: content_type,
          contextUrl: context_url))
      else
        RDF::Util::File.open_file(url, **options, &block)
      end
    end

    ##
    # The default serializer for serialzing Ruby Objects to JSON.
    #
    # Defaults to `MultiJson.dump`
    #
    # @param [Object] object
    # @param [Array<Object>] args
    #   other arguments that may be passed for some specific implementation.
    # @param [Hash<Symbol, Object>] options
    #   options passed from the invoking context.
    def self.serializer(object, *args, **options)
      # de-alias any objects to avoid the use of aliases and anchors
      "%YAML 1.2\n" + Representation.dump(object, **options)
    end
  end
end

