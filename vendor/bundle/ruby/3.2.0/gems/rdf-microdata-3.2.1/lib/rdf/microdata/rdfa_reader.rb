require 'rdf/rdfa'

module RDF::Microdata
  ##
  # Update DOM to turn Microdata into RDFa and parse using the RDFa Reader
  class RdfaReader < RDF::RDFa::Reader
    # The transformed DOM using RDFa
    # @return [RDF::HTML::Document]
    attr_reader :rdfa

    def self.format(klass = nil)
      if klass.nil?
        RDF::Microdata::Format
      else
        super
      end
    end

    ##
    # Initializes the RdfaReader instance.
    #
    # @param  [IO, File, String] input
    #   the input stream to read
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize`)
    # @return [reader]
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [RDF::ReaderError] if _validate_
    def initialize(input = $stdin, **options, &block)
      @options = options
      log_debug('', "using RDFa transformation reader")

      input = case input
      when ::Nokogiri::XML::Document, ::Nokogiri::HTML::Document then input
      else
        # Try to detect charset from input
        options[:encoding] ||= input.charset if input.respond_to?(:charset)
        
        # Otherwise, default is utf-8
        options[:encoding] ||= 'utf-8'
        options[:encoding] = options[:encoding].to_s if options[:encoding]
        begin
          input = input.read if input.respond_to?(:read)
          ::Nokogiri::HTML5(input.force_encoding(options[:encoding]), max_parse_errors: 1000)
        rescue LoadError, NoMethodError
          ::Nokogiri::HTML.parse(input, base_uri.to_s, options[:encoding])
        end
      end

      # For all members having @itemscope
      input.css("[itemscope]").each do |item|
        # Get @itemtypes to create @type and @vocab
        item.attribute('itemscope').remove
        if item['itemtype']
          # Only absolute URLs
          types = item.attribute('itemtype').
            remove.
            to_s.
            split(/\s+/).
            select {|t| RDF::URI(t).absolute?}

          item['typeof'] = types.join(' ') unless types.empty?
          if vocab = types.first
            vocab = begin
              type_vocab = vocab.to_s.sub(/([\/\#])[^\/\#]*$/, '\1')
              Registry.new(type_vocab) if type_vocab
            end
            item['vocab'] = vocab.uri.to_s if vocab
          end
        end
        item['typeof'] ||= ''

        # Change each itemid attribute to an resource attribute with the same value
        if item['itemid']
          id = item.attribute('itemid').remove
          item['resource'] = id
        end
      end

      # Add @resource for all itemprop values of object based on a @data value
      input.css("object[itemprop][data]").each do |item|
        item['resource'] ||= item['data']
      end

      # Replace all @itemprop values with @property
      input.css("[itemprop]").each {|item| item['property'] = item.attribute('itemprop').remove}

      # Wrap all @itemref properties
      input.css("[itemref]").each do |item|
        item_vocab = item['vocab'] || item.ancestors.detect {|a| a.attribute('vocab')}
        item_vocab = item_vocab.to_s if item_vocab

        item.attribute('itemref').remove.to_s.split(/\s+/).each do |ref|
          if referenced = input.css("##{ref}")
            # Add @vocab to referenced using the closest ansestor having @vocab of item.
            # If the element with id reference has no resource attribute, add a resource attribute whose value is a NUMBER SIGN U+0023 followed by reference to the element.
            # If the element with id reference has no typeof attribute, add a typeof="rdfa:Pattern" attribute to the element.
            # FIXME: This broke in Nokogiri 13.0
            referenced.wrap(%(<div vocab="#{item_vocab}" resource="##{ref}" typeof="rdfa:Pattern" />))

            # Add a link child element to the element that represents the item, with a rel="rdfa:copy" attribute and an href attribute whose value is a NUMBER SIGN U+0023 followed by reference
            link = ::Nokogiri::XML::Node.new('link', input)
            link['rel'] = 'rdfa:copy'
            link['href'] = "##{ref}"
            item << link
          end
        end
      end

      @rdfa = input
      log_debug('', "Transformed document: #{input.to_html}")

      options = options.merge(
        library: :nokogiri,
        reference_folding: true,
        host_language: :html5,
        version: :"rdfa1.1")

      # Rely on RDFa reader
      super(input, **options, &block)
    end
  end
end