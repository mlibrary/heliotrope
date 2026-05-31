require 'json'
module RDF::Microdata

  # Interface to registry
  class Registry
    # @return [RDF::URI] Prefix of vocabulary
    attr_reader :uri

    # @return [Hash] properties
    attr_reader :properties

    ##
    # Initialize the registry from a URI or file path
    #
    # @param [String] registry_uri
    def self.load_registry(registry_uri)
      return if @registry_uri == registry_uri

      json = RDF::Util::File.open_file(registry_uri) { |f| ::JSON.load(f) }

      @prefixes = {}
      json.each do |prefix, elements|
        next unless elements.is_a?(Hash)
        properties = elements.fetch("properties", {})
        @prefixes[prefix] = Registry.new(prefix, properties)
      end
      @registry_uri = registry_uri
    end

    ##
    # Initialize registry for a particular prefix URI
    #
    # @param [RDF::URI] prefixURI
    # @param [Hash] properties ({})
    def initialize(prefixURI, properties = {})
      @uri = prefixURI
      @properties = properties
      @property_base = prefixURI.to_s
      # Append a '#' for fragment if necessary
      @property_base += '#' unless %w(/ #).include?(@property_base[-1,1])
    end

    ##
    # Find a registry entry given a type URI
    #
    # @param [RDF::URI] type
    # @return [Registry]
    def self.find(type) 
      @prefixes ||= {}
      k = @prefixes.keys.detect {|key| type.to_s.index(key) == 0 }
      @prefixes[k] if k
    end
    
    ##
    # Generate a predicateURI given a `name`
    #
    # @param [#to_s] name
    # @param [RDF::URI] base_uri base URI for resolving `name`.
    # @return [RDF::URI]
    def predicateURI(name, base_uri)
      u = RDF::URI(name)
      # 1) If _name_ is an _absolute URL_, return _name_ as a _URI reference_
      return u if u.absolute?
      
      n = frag_escape(name)
      if uri.nil?
        # 2) If current vocabulary from context is null, there can be no current vocabulary.
        #    Return the URI reference that is the document base with its fragment set to the fragment-escaped value of name
        u = RDF::URI(base_uri.to_s)
        u.fragment = frag_escape(name)
        u
      else
        # 4) If scheme is vocabulary return the URI reference constructed by appending the fragment escaped value of name to current vocabulary, separated by a U+0023 NUMBER SIGN character (#) unless the current vocabulary ends with either a U+0023 NUMBER SIGN character (#) or SOLIDUS U+002F (/).
        RDF::URI(@property_base + n)
      end
    end

    ##
    # Yield a equivalentProperty or subPropertyOf if appropriate
    #
    # @param [RDF::URI] predicateURI
    # @yield equiv
    # @yieldparam [RDF::URI] equiv
    def expand(predicateURI)
      tok = tokenize(predicateURI)
      if @properties[tok].is_a?(Hash)
        value = @properties[tok].fetch("subPropertyOf", nil)
        value ||= @properties[tok].fetch("equivalentProperty", nil)

        Array(value).each {|equiv| yield RDF::URI(equiv)}
      end
    end

    ##
    # Turn a predicateURI into a simple token
    # @param [RDF::URI] predicateURI
    # @return [String]
    def tokenize(predicateURI)
      predicateURI.to_s.sub(@property_base, '')
    end

    ##
    # Fragment escape a name
    def frag_escape(name)
      name.to_s.gsub(/["#%<>\[\\\]^{|}]/) {|c| '%' + c.unpack('H2' * c.bytesize).join('%').upcase}
    end
  end

end