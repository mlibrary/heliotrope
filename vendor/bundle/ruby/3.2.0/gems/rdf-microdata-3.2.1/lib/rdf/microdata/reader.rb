require 'nokogiri'
require 'rdf/xsd'
require 'json'

module RDF::Microdata
  ##
  # An Microdata parser in Ruby
  #
  # Based on processing rules, amended with the following:
  #
  # @see https://dvcs.w3.org/hg/htmldata/raw-file/0d6b89f5befb/microdata-rdf/index.html
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format
    include Expansion
    include RDF::Util::Logger
    URL_PROPERTY_ELEMENTS = %w(a area audio embed iframe img link object source track video)

    # @private
    class CrawlFailure < StandardError; end

    # @return [Module] Returns the HTML implementation module for this reader instance.
    attr_reader :implementation

    # @return [Hash{Object => RDF::Resource}] maps RDF elements (items) to resources
    attr_reader :memory

    ##
    # Returns the base URI determined by this reader.
    #
    # @example
    #   reader.prefixes[:dc]  #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def base_uri
      @options[:base_uri]
    end

    ##
    # Reader options
    # @see https://ruby-rdf.github.io/rdf/RDF/Reader#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :rdfa,
          datatype: TrueClass,
          on: ["--rdfa"],
          description: "Transform and parse as RDFa.") {true},
      ]
    end

    ##
    # Redirect for RDFa Reader given `:rdfa` option
    #
    # @private
    def self.new(input = nil, **options, &block)
      klass = if options[:rdfa]
        # Requires rdf-rdfa gem to be loaded
        begin
          require 'rdf/rdfa'
        rescue LoadError
          raise ReaderError, "Use of RDFa-based reader requires rdf-rdfa gem"
        end
        RdfaReader
      else
        self
      end
      reader = klass.allocate
      reader.send(:initialize, input, **options, &block)
      reader
    end

    ##
    # Initializes the Microdata reader instance.
    #
    # @param  [Nokogiri::HTML::Document, Nokogiri::XML::Document, IO, File, String] input
    #   the input stream to read
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Encoding] :encoding     (Encoding::UTF_8)
    #   the encoding of the input stream (Ruby 1.9+)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean]  :canonicalize (false)
    #   whether to canonicalize parsed literals
    # @option options [Boolean]  :intern       (true)
    #   whether to intern all parsed URIs
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs
    # @option options [#to_s]    :registry
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [Error] Raises `RDF::ReaderError` when validating
    def initialize(input = $stdin, **options, &block)
      super do
        @library = :nokogiri

        require "rdf/microdata/reader/#{@library}"
        @implementation = Nokogiri
        self.extend(@implementation)

        input.rewind if input.respond_to?(:rewind)
        initialize_html(input, **options) rescue log_fatal($!.message, exception: RDF::ReaderError)

        log_error("Empty document") if root.nil?
        log_error(doc_errors.map(&:message).uniq.join("\n")) if !doc_errors.empty?

        log_debug('', "library = #{@library}")

        # Load registry
        begin
          registry_uri = options[:registry] || RDF::Microdata::DEFAULT_REGISTRY
          log_debug('', "registry = #{registry_uri.inspect}")
          Registry.load_registry(registry_uri)
        rescue JSON::ParserError => e
          log_fatal("Failed to parse registry: #{e.message}", exception: RDF::ReaderError) if (root.nil? && validate?)
        end
        
        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # Reads to graph and performs expansion if required.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        @callback = block

        # parse
        parse_whole_document(@doc, base_uri)

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    end

    ##
    # Iterates the given block for each RDF triple in the input.
    #
    # @yield  [subject, predicate, object]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @return [void]
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end
    
    private

    # Keep track of allocated BNodes
    def bnode(value = nil)
      @bnode_cache ||= {}
      @bnode_cache[value.to_s] ||= RDF::Node.new(value)
    end
    
    # Figure out the document path, if it is an Element or Attribute
    def node_path(node)
      "<#{base_uri}>#{node.respond_to?(:display_path) ? node.display_path : node}"
    end

    ##
    # add a statement, object can be literal or URI or bnode
    #
    # @param [Nokogiri::XML::Node, any] node XML Node or string for showing context
    #
    # @param [URI, BNode] subject the subject of the statement
    # @param [URI] predicate the predicate of the statement
    # @param [URI, BNode, Literal] object the object of the statement
    # @return [Statement] Added statement
    # @raise [ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_triple(node, subject, predicate, object)
      statement = RDF::Statement.new(subject, predicate, object)
      log_error "#{statement.inspect} is invalid" if statement.invalid?
      log_debug(node) {"statement: #{RDF::NTriples.serialize(statement)}"}
      @callback.call(statement)
    end

    # Parsing a Microdata document (this is *not* the recursive method)
    def parse_whole_document(doc, base)
      base = doc_base(base)
      @memory = {}
      options[:base_uri] = if (base)
        # Strip any fragment from base
        base = base.to_s.split('#').first
        base = uri(base)
      else
        base = RDF::URI("")
      end
      
      log_info(nil) {"parse_whole_doc: base='#{base}'"}

      # 1) For each element that is also a top-level item, Generate the triples for that item using the evaluation context.
      getItems.each do |el|
        log_depth {generate_triples(el, Registry.new(nil))}
      end

      log_info(doc, "parse_whole_doc: traversal complete")
    end

    ##
    # Generate triples for an item
    #
    # @param [RDF::Resource] item
    # @param [Registry] vocab
    # @option ec [Hash{Nokogiri::XML::Element} => RDF::Resource] memory
    # @option ec [RDF::Resource] :current_vocabulary
    # @return [RDF::Resource]
    def generate_triples(item, vocab)
      # 1) If there is an entry for item in memory, then let subject be the subject of that entry. Otherwise, if item has a global identifier and that global identifier is an absolute URL, let subject be that global identifier. Otherwise, let subject be a new blank node.
      subject = if memory.include?(item.node)
        memory[item.node][:subject]
      elsif item.has_attribute?('itemid')
        uri(item.attribute('itemid'), item.base || base_uri)
      end || RDF::Node.new
      memory[item.node] ||= {}

      log_debug(item) {"gentrips(2): subject=#{subject.inspect}, vocab: #{vocab.inspect}"}

      # 2) Add a mapping from item to subject in memory, if there isn't one already.
      memory[item.node][:subject] ||= subject
      
      # 3) For each type returned from element.itemType of the element defining the item.
      # 4) Set vocab to the first value returned from element.itemType of the element defining the item.
      type = nil
      item.attribute('itemtype').to_s.split(' ').map{|n| uri(n)}.select(&:absolute?).each do |t|
        #   3.1. If type is an absolute URL, generate the following triple:
        type ||= t
        add_triple(item, subject, RDF.type, t)
      end

      # 6) If the registry contains a URI prefix that is a character for character match of vocab up to the length of the URI prefix, set vocab as that URI prefix.
      if type || vocab.nil?
        vocab = Registry.find(type) || begin
          type_vocab = type.to_s.sub(/([\/\#])[^\/\#]*$/, '\1') unless type.nil?
          log_debug(item)  {"gentrips(7): type_vocab=#{type_vocab.inspect}"}
          Registry.new(type_vocab)
        end
      end

      # Otherwise, use vocab from evaluation context
      log_debug(item) {"gentrips(8): vocab: #{vocab.inspect}"}

      # 9. For each element _element_ that has one or more property names and is one of the properties of the item _item_, run the following substep:
      props = item_properties(item)
      # 9.1. For each name name in element's property names, run the following substeps:
      props.each do |element|
        element.attribute('itemprop').to_s.split(' ').compact.each do |name|
          log_debug(item) {"gentrips(9.1): name=#{name.inspect}, vocab=#{vocab.inspect}"}
          # 9.1.2) Let predicate be the result of generate predicate URI using context and name. Update context by setting current name to predicate.
          predicate = vocab.predicateURI(name, base_uri)

          # 9.1.3) Let value be the property value of element.
          value = property_value(element)
          log_debug(item) {"gentrips(9.1.3) value=#{value.inspect}"}
          
          # 9.1.4) If value is an item, then generate the triples for value context. Replace value by the subject returned from those steps.
          if value.is_a?(Hash)
            value = generate_triples(element, vocab) 
            log_debug(item) {"gentrips(9.1.4): value=#{value.inspect}"}
          end

          # 9.1.4) Generate the following triple:
          add_triple(item, subject, predicate, value)

          # 9.1.5) If an entry exists in the registry for name in the vocabulary associated with vocab having the key subPropertyOf or equivalentProperty
          vocab.expand(predicate) do |equiv|
            log_debug(item) {"gentrips(9.1.5): equiv=#{equiv.inspect}"}
            # for each such value equiv, generate the following triple
            add_triple(item, subject, equiv, value)
          end 
        end
      end

      # 10. For each element element that has one or more reverse property names and is one of the reverse properties of the item item, run the following substep:
      props = item_properties(item, true)
      # 10.1. For each name name in element's reverse property names, run the following substeps:
      props.each do |element|
        element.attribute('itemprop-reverse').to_s.split(' ').compact.each do |name|
          log_debug(item) {"gentrips(10.1): name=#{name.inspect}"}
          
          # 10.1.2) Let predicate be the result of generate predicate URI using context and name. Update context by setting current name to predicate.
          predicate = vocab.predicateURI(name, base_uri)
          
          # 10.1.3) Let value be the property value of element.
          value = property_value(element)
          log_debug(item) {"gentrips(10.1.3) value=#{value.inspect}"}

          # 10.1.4) If value is an item, then generate the triples for value context. Replace value by the subject returned from those steps.
          if value.is_a?(Hash)
            value = generate_triples(element, vocab) 
            log_debug(item) {"gentrips(10.1.4): value=#{value.inspect}"}
          elsif value.is_a?(RDF::Literal)
            # 10.1.5) Otherwise, if value is a literal, ignore the value and continue to the next name; it is an error for the value of @itemprop-reverse to be a literal
            log_error(element, "Value of @itemprop-reverse may not be a literal: #{value.inspect}")
            next
          end

          # 10.1.6) Generate the following triple
          add_triple(item, value, predicate, subject)
        end
      end

      # 11) Return subject
      subject
    end

    ##
    # To find the properties of an item defined by the element root, the user agent must try to crawl the properties of the element root, with an empty list as the value of memory: if this fails, then the properties of the item defined by the element root is an empty list; otherwise, it is the returned list.
    #
    # @param [Nokogiri::XML::Element] item
    # @param [Boolean] reverse (false) return reverse properties
    # @return [Array<Nokogiri::XML::Element>]
    #   List of property elements for an item
    def item_properties(item, reverse = false)
      log_debug(item, "item_properties (#{reverse.inspect})")
      crawl_properties(item, [], reverse)
    rescue CrawlFailure => e
      log_error(item, e.message)
      return []
    end
    
    ##
    # To crawl the properties of an element root with a list memory, the user agent must run the following steps. These steps either fail or return a list with a count of errors. The count of errors is used as part of the authoring conformance criteria below.
    #
    # @param [Nokogiri::XML::Element] root
    # @param [Array<Nokokogiri::XML::Element>] memo
    # @param [Boolean] reverse crawl reverse properties
    # @return [Array<Nokogiri::XML::Element>]
    #   Resultant elements
    def crawl_properties(root, memo, reverse)
      # 1. If root is in memo, then the algorithm fails; abort these steps.
      raise CrawlFailure, "crawl_props mem already has #{root.inspect}" if memo.include?(root)
      
      # 2. Collect all the elements in the item root; let results be the resulting list of elements, and errors be the resulting count of errors.
      results = elements_in_item(root)
      log_debug(root) {"crawl_properties reverse=#{reverse.inspect} results=#{results.map {|e| node_path(e)}.inspect}"}

      # 3. Remove any elements from results that do not have an @itemprop (@itemprop-reverse) attribute specified.
      results = results.select {|e| e.has_attribute?(reverse ? 'itemprop-reverse' : 'itemprop')}
      
      # 4. Let new memo be a new list consisting of the old list memo with the addition of root.
      raise CrawlFailure, "itemref recursion" if memo.detect {|n| root.node.object_id == n.node.object_id}
      new_memo = memo + [root]
      
      # 5. For each element in results that has an @itemscope attribute specified, crawl the properties of the element, with new memo as the memo.
      results.select {|e| e.has_attribute?('itemscope')}.each do |element|
        log_depth {crawl_properties(element, new_memo, reverse)}
      end
      
      results
    end

    ##
    # To collect all the elements in the item root, the user agent must run these steps. They return a list of elements.
    #
    # @param [Nokogiri::XML::Element] root
    # @return [Array<Nokogiri::XML::Element>]
    #   Resultant elements and error count
    # @raise [CrawlFailure] on element recursion
    def elements_in_item(root)
      # Let results and pending be empty lists of elements.
      # Let errors be zero.
      results, memo, errors = [], [], 0
      
      # Add all the children elements of root to pending.
      pending = root.elements
      
      # If root has an itemref attribute, split the value of that itemref attribute on spaces.
      # For each resulting token ID, 
      root.attribute('itemref').to_s.split(' ').each do |id|
        log_debug(root) {"elements_in_item itemref id #{id}"}
        # if there is an element in the home subtree of root with the ID ID,
        # then add the first such element to pending.
        id_elem = find_element_by_id(id)
        pending << id_elem if id_elem
      end
      log_debug(root) {"elements_in_item pending #{pending.inspect}"}

      # Loop: Remove an element from pending and let current be that element.
      while current = pending.shift
        if memo.include?(current)
          raise CrawlFailure, "elements_in_item: results already includes #{current.inspect}"
        elsif !current.has_attribute?('itemscope')
          # If current is not already in results and current does not have an itemscope attribute, then: add all the child elements of current to pending.
          pending += current.elements
        end
        memo << current
        
        # If current is not already in results, then: add current to results.
        results << current unless results.include?(current)
      end

      results
    end

    ##
    #
    def property_value(element)
      base = element.base || base_uri
      log_debug(element) {"property_value(#{element.name}): base #{base.inspect}"}
      value = case
      when element.has_attribute?('itemscope')
        {}
      when element.has_attribute?('content')
        RDF::Literal.new(element.attribute('content').to_s, language: element.language)
      when %w(data meter).include?(element.name) && element.attribute('value')
        # Lexically scan value and assign appropriate type, otherwise, leave untyped
        v = element.attribute('value').to_s
        datatype = %w(Integer Float Double).map {|t| RDF::Literal.const_get(t)}.detect do |dt|
          v.match(dt::GRAMMAR)
        end || RDF::Literal
        datatype = RDF::Literal::Double if datatype == RDF::Literal::Float
        datatype.new(v)
      when %w(audio embed iframe img source track video).include?(element.name)
        uri(element.attribute('src'), base)
      when %w(a area link).include?(element.name)
        uri(element.attribute('href'), base)
      when %w(object).include?(element.name)
        uri(element.attribute('data'), base)
      when %w(time).include?(element.name)
        # Lexically scan value and assign appropriate type, otherwise, leave untyped
        v = (element.attribute('datetime') || element.text).to_s
        datatype = %w(Date Time DateTime Duration).map {|t| RDF::Literal.const_get(t)}.detect do |dt|
          v.match(dt::GRAMMAR)
        end || RDF::Literal
        datatype.new(v, language: element.language)
      else
        RDF::Literal.new(element.inner_text, language: element.language)
      end
      log_debug(element) {"  #{value.inspect}"}
      value
    end

    # Fixme, what about xml:base relative to element?
    def uri(value, base = nil)
      value = if base
        base = uri(base) unless base.is_a?(RDF::URI)
        base.join(value.to_s)
      else
        RDF::URI(value.to_s)
      end
      value.validate! if validate?
      value.canonicalize! if canonicalize?
      value = RDF::URI.intern(value) if intern?
      value
    end
  end
end