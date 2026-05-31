# encoding: UTF-8

require 'json'
require 'json/ld'
require 'bcp47'
require 'addressable/template'
require 'rdf/xsd'
require 'yaml'  # used by BCP47, which should have required it.

##
# CSVM Metadata processor
#
# * Extracts Metadata from file or Hash definition
# * Extract Embedded Metadata from a CSV file
# * Return table-level annotations
# * Return Column-level annotations
# * Return row iterator with column information
#
# @author [Gregg Kellogg](https://greggkellogg.net/)
module RDF::Tabular
  class Metadata
    include RDF::Util::Logger

    # Hash representation
    # @return [Hash<Symbol,Object>]
    attr_accessor :object

    # Inheritect properties, valid for all types
    INHERITED_PROPERTIES = {
      aboutUrl:           :uri_template,
      datatype:           :atomic,
      default:            :atomic,
      lang:               :atomic,
      null:               :atomic,
      ordered:            :atomic,
      propertyUrl:        :uri_template,
      required:           :atomic,
      separator:          :atomic,
      textDirection:      :atomic,
      valueUrl:           :uri_template,
    }.freeze
    INHERITED_DEFAULTS = {
      default:            "".freeze,
      lang:               "und",
      null:               "".freeze,
      ordered:            false,
      required:           false,
      textDirection:      "ltr".freeze,
    }.freeze

    # Valid datatypes
    DATATYPES = {
      anyAtomicType:      RDF::XSD.anyAtomicType,
      anyURI:             RDF::XSD.anyURI,
      base64Binary:       RDF::XSD.basee65Binary,
      boolean:            RDF::XSD.boolean,
      byte:               RDF::XSD.byte,
      date:               RDF::XSD.date,
      dateTime:           RDF::XSD.dateTime,
      dayTimeDuration:    RDF::XSD.dayTimeDuration,
      dateTimeStamp:      RDF::XSD.dateTimeStamp,
      decimal:            RDF::XSD.decimal,
      double:             RDF::XSD.double,
      duration:           RDF::XSD.duration,
      float:              RDF::XSD.float,
      ENTITY:             RDF::XSD.ENTITY,
      gDay:               RDF::XSD.gDay,
      gMonth:             RDF::XSD.gMonth,
      gMonthDay:          RDF::XSD.gMonthDay,
      gYear:              RDF::XSD.gYear,
      gYearMonth:         RDF::XSD.gYearMonth,
      hexBinary:          RDF::XSD.hexBinary,
      int:                RDF::XSD.int,
      integer:            RDF::XSD.integer,
      language:           RDF::XSD.language,
      long:               RDF::XSD.long,
      Name:               RDF::XSD.Name,
      NCName:             RDF::XSD.NCName,
      negativeInteger:    RDF::XSD.negativeInteger,
      NMTOKEN:            RDF::XSD.NMTOKEN,
      nonNegativeInteger: RDF::XSD.nonNegativeInteger,
      nonPositiveInteger: RDF::XSD.nonPositiveInteger,
      normalizedString:   RDF::XSD.normalizedString,
      NOTATION:           RDF::XSD.NOTATION,
      positiveInteger:    RDF::XSD.positiveInteger,
      QName:              RDF::XSD.Qname,
      short:              RDF::XSD.short,
      string:             RDF::XSD.string,
      time:               RDF::XSD.time,
      token:              RDF::XSD.token,
      unsignedByte:       RDF::XSD.unsignedByte,
      unsignedInt:        RDF::XSD.unsignedInt,
      unsignedLong:       RDF::XSD.unsignedLong,
      unsignedShort:      RDF::XSD.unsignedShort,
      yearMonthDuration:  RDF::XSD.yearMonthDuration,

      any:                RDF::XSD.anyAtomicType,
      binary:             RDF::XSD.base64Binary,
      datetime:           RDF::XSD.dateTime,
      html:               RDF.HTML,
      json:               RDF::Tabular::CSVW.JSON,
      number:             RDF::XSD.double,
      xml:                RDF.XMLLiteral,
    }

    # A name is restricted according to the following RegExp.
    # @return [RegExp]
    NAME_SYNTAX = %r(\A(?:_col|[a-zA-Z0-9]|%\h\h)([a-zA-Z0-9\._]|%\h\h)*\z)

    # Local version of the context
    # @return [JSON::LD::Context]
    LOCAL_CONTEXT = ::JSON::LD::Context.new.parse(File.expand_path("../../../../etc/csvw.jsonld", __FILE__)).freeze

    # ID of this Metadata
    # @return [RDF::URI]
    attr_reader :id

    # URL of related resource
    # @return [RDF::URI]
    attr_reader :url

    # Parent of this Metadata (TableGroup for Table, ...)
    # @return [Metadata]
    attr_reader :parent

    # Filename(s) (URI) of opened metadata, if any
    # May be plural when merged
    # @return [Array<RDF::URI>] filenames
    attr_reader :filenames

    ##
    # Attempt to retrieve the file at the specified path. If it is valid metadata, create a new Metadata object from it, otherwise, an empty Metadata object
    #
    # @param [String] path
    # @param [Hash{Symbol => Object}] options
    #   see `RDF::Util::File.open_file` in RDF.rb and {new}
    # @yield [Metadata]
    # @raise [IOError] if file not found
    def self.open(path, **options)
      options = options.merge(
        headers: {
          'Accept' => 'application/ld+json, application/json'
        }
      )
      path = "file:#{path}" if RDF::URI(path).relative?
      RDF::Util::File.open_file(path, **options) do |file|
        self.new(file, **options.merge(base: path, filenames: path))
      end
    end

    # Return the well-known configuration for a file, and remember using a weak-reference cache to avoid uncessary retreivles.
    # @param [String] base the URL used for finding the file
    # @return [Array<String>, false]
    def self.site_wide_config(base)
      require 'rdf/util/cache' unless defined?(::RDF::Util::Cache)
      @cache ||= RDF::Util::Cache.new(-1)

      config_loc = RDF::URI(base).join(SITE_WIDE_CONFIG).to_s
      # Only load if we haven't tried before. Use `SITE_WIDE_DEFAULT` if not found
      if @cache[config_loc].nil?
        @cache[config_loc] = RDF::Util::File.open_file(config_loc) do |rd|
          rd.each_line.to_a
        end rescue SITE_WIDE_DEFAULT.split
      end
      @cache[config_loc]
    end

    ##
    # Return metadata for a file, based on user-specified, linked, and site-wide location configuration from an input file
    # @param [IO, StringIO] input
    # @param [Hash{Symbol => Object}] options
    # @option options [Metadata, Hash, String, RDF::URI] :metadata user supplied metadata, merged on top of extracted metadata. If provided as a URL, Metadata is loade from that location
    # @option options [RDF::URI] :base
    #   The Base URL to use when expanding the document. This overrides the value of `input` if it is a URL. If not specified and `input` is not an URL, the base URL defaults to the current document URL if in a browser context, or the empty string if there is no document context.
    # @return [Metadata]
    def self.for_input(input, **options)
      base = options[:base]

      # Use user metadata, if provided
      metadata = case options[:metadata]
      when Metadata then options[:metadata]
      when Hash
        Metadata.new(options[:metadata], **options.merge(reason: "load user metadata: #{options[:metadata].inspect}"))
      when String, RDF::URI
        Metadata.open(options[:metadata], **options.merge(filenames: options[:metadata], reason: "load user metadata: #{options[:metadata].inspect}"))
      end

      # Search for metadata until found

      # load link metadata, if available
      if !metadata && input.respond_to?(:links) && 
        link = input.links.find_link(%w(rel describedby))
        link_loc = RDF::URI(base).join(link.href).to_s
        md = Metadata.open(link_loc, **options.merge(filenames: link_loc, reason: "load linked metadata: #{link_loc}"))
        if md
          # Metadata must describe file to be useful
          if md.describes_file?(base)
            metadata = md
          else
            log_warn("Found metadata at #{link_loc}, which does not describe #{base}, ignoring", **options)
          end
        end
      end

      locs = []
      # If we still don't have metadata, load the site-wide configuration file and use templates found there as locations
      if !metadata && base
        templates = site_wide_config(base)
        log_debug("for_input", **options) {"templates: #{templates.map(&:to_s).inspect}"}
        locs = templates.map do |template|
          t = Addressable::Template.new(template)
          mapped = t.expand(url: base).to_s
          mapped = RDF::URI.decode(mapped) if options[:decode_uri]
          RDF::URI(base).join(mapped)
        end
        log_debug("for_input", **options) {"locs: #{locs.map(&:to_s).inspect}"}

        locs.each do |loc|
          metadata ||= begin
            md = Metadata.open(loc, **options.merge(filenames: loc, reason: "load found metadata: #{loc}"))
            # Metadata must describe file to be useful
            if md
              # Metadata must describe file to be useful
              if md.describes_file?(base)
                md
              else
                log_warn("Found metadata at #{loc}, which does not describe #{base}, ignoring", **options)
                nil
              end
            end
          rescue IOError
            log_debug("for_input", **options) {"failed to load found metadata #{loc}: #{$!}"}
            nil
          end
        end
      end

      # Return either the merge or user- and found-metadata, any of these, or an empty TableGroup
      metadata = case
      when metadata then metadata
      when base     then TableGroup.new({"@context" => "http://www.w3.org/ns/csvw", tables: [{url: base}]}, **options)
      else               TableGroup.new({"@context" => "http://www.w3.org/ns/csvw", tables: [{url: nil}]}, **options)
      end

      # Make TableGroup, if not already
      metadata.is_a?(TableGroup) ? metadata : metadata.to_table_group
    end

    ##
    # @private
    def self.new(input, **options)
      # Triveal case
      return input if input.is_a?(Metadata)

      object = case input
      when Hash then input
      when IO, StringIO then ::JSON.parse(input.read)
      else ::JSON.parse(input.to_s)
      end

      raise ::JSON::ParserError unless object.is_a?(Hash)

      unless options[:parent]
        # Add context, if not set (which it should be)
        object['@context'] ||= options.delete(:@context) || options[:context]
      end

      klass = case
        when !self.equal?(RDF::Tabular::Metadata)
          self # subclasses can be directly constructed without type dispatch
        else
          type =  options[:type].to_sym if options[:type]

          # Figure out type by @type
          type ||= object['@type'].to_sym if object['@type']

          # Otherwise, Figure out type by site
          object_keys = object.keys.map(&:to_s)
          type ||= case
          when %w(tables).any? {|k| object_keys.include?(k)} then :TableGroup
          when %w(dialect tableSchema transformations).any? {|k| object_keys.include?(k)} then :Table
          when %w(targetFormat scriptFormat source).any? {|k| object_keys.include?(k)} then :Template
          when %w(columns primaryKey foreignKeys rowTitles).any? {|k| object_keys.include?(k)} then :Schema
          when %w(name virtual).any? {|k| object_keys.include?(k)} then :Column
          when %w(commentPrefix delimiter doubleQuote encoding header headerRowCount).any? {|k| object_keys.include?(k)} then :Dialect
          when %w(lineTerminators quoteChar skipBlankRows skipColumns skipInitialSpace skipRows trim).any? {|k| object_keys.include?(k)} then :Dialect
          end

          case type.to_s.to_sym
          when :TableGroup, :"" then RDF::Tabular::TableGroup
          when :Table then RDF::Tabular::Table
          when :Template then RDF::Tabular::Transformation
          when :Schema then RDF::Tabular::Schema
          when :Column then RDF::Tabular::Column
          when :Dialect then RDF::Tabular::Dialect
          else
            raise Error, "Unknown metadata type: #{type.inspect}"
          end
        end

      md = klass.allocate
      md.send(:initialize, object, **options)
      md
    rescue ::JSON::ParserError
      raise Error, "Expected input to be a JSON Object"
    end

    ##
    # Create Metadata from IO, Hash or String
    #
    # @param [Metadata, Hash, #read] input
    # @param [Hash{Symbol => Object}] options
    # @option options [:TableGroup, :Table, :Transformation, :Schema, :Column, :Dialect] :type
    #   Type of schema, if not set, intuited from properties
    # @option options [JSON::LD::Context] context
    #   Context used for this metadata. Taken from input if not provided
    # @option options [RDF::URI] :base
    #   The Base URL to use when expanding the document. This overrides the value of `input` if it is a URL. If not specified and `input` is not an URL, the base URL defaults to the current document URL if in a browser context, or the empty string if there is no document context.
    # @option options [Boolean] :decode_uri
    #   Decode %-encodings in the result of a URI Template operation.
    # @option options [Boolean] :normalize normalize the object
    # @option options [Boolean] :validate Strict metadata validation
    # @raise [Error]
    # @return [Metadata]
    def initialize(input, **options)
      @options = options.dup

      # Parent of this Metadata, if any
      @parent = @options[:parent]

      # Get context from input
      # Optimize by using built-in version of context, and just extract @base, @lang
      opt_base = @options[:base]
      opt_base ||= input.base_uri if input.respond_to?(:base_uri)
      opt_base ||= input.filename if input.respond_to?(:filename)

      @context = case input['@context']
      when Array
        log_warn "Context missing required value 'http://www.w3.org/ns/csvw'" unless input['@context'].include?('http://www.w3.org/ns/csvw')
        c = LOCAL_CONTEXT.dup
        c.base = RDF::URI(opt_base)
        obj = input['@context'].detect {|e| e.is_a?(Hash)} || {}
        raise Error, "@context has object with properties other than @base and @language" unless (obj.keys.map(&:to_s) - %w(@base @language)).empty?
        c.parse(obj)
      when Hash
        log_warn "Context missing required value 'http://www.w3.org/ns/csvw'"
        c = LOCAL_CONTEXT.dup
        c.base = RDF::URI(opt_base)
        c.parse(input['@context'])
      when "http://www.w3.org/ns/csvw"
        LOCAL_CONTEXT.dup
        c = LOCAL_CONTEXT.dup
        c.base = RDF::URI(opt_base)
        c
      else
        if self.is_a?(TableGroup) || self.is_a?(Table) && !@parent
          log_warn "Context missing required value 'http://www.w3.org/ns/csvw'"
          LOCAL_CONTEXT.dup
          c = LOCAL_CONTEXT.dup
          c.base = RDF::URI(opt_base)
          c
        end
      end

      reason = @options.delete(:reason)

      @options[:base] = @context ? @context.base : RDF::URI(opt_base)

      if @context && @context.default_language && !BCP47::Language.identify(@context.default_language.to_s)
        log_warn "Context has invalid @language (#{@context.default_language.inspect}): expected valid BCP47 language tag"
        @context.default_language = nil
      end

      @filenames = Array(@options[:filenames]).map {|fn| RDF::URI(fn)} if @options[:filenames]
      @properties = self.class.const_get(:PROPERTIES)
      @required = self.class.const_get(:REQUIRED)

      @object = {}

      log_depth do
        # Input was parsed in .new
        # Metadata is object with symbolic keys
        input.each do |key, value|
          key = key.to_sym
          case key
          when :url
            # URL of CSV relative to metadata
            object[:url] = value
            @url = @options[:base].join(value)
            @options[:base] = @url if @context # Use as base for expanding IRIs
          when :@id
            # metadata identifier
            object[:@id] = if value.is_a?(String)
              value
            else
              log_warn "#{type} has invalid property '@id' (#{value.inspect}): expected a string"
              ""  # Default value
            end
            @id = @options[:base].join(object[:@id])
          else
            if @properties.has_key?(key) || INHERITED_PROPERTIES.has_key?(key)
              self.send("#{key}=".to_sym, value)
            else
              object[key] = value
            end
          end
        end
      end

      # Set type from @type, if present and not otherwise defined
      @type = object[:@type].to_sym if object[:@type]

      if options[:normalize]
        # If normalizing, also remove remaining @context
        self.normalize!
        @context = nil
        object.delete(:@context)
      end

      if reason
        log_debug("md#initialize") {reason}
        log_debug("md#initialize") {"filenames: #{filenames}"}
        log_debug("md#initialize") {"#{inspect}, parent: #{!@parent.nil?}, context: #{!@context.nil?}"} unless is_a?(Dialect)
      end
    end

    # Getters and Setters
    INHERITED_PROPERTIES.each do |key, type|
      define_method(key) do
        object.fetch(key) do
          parent ? parent.send(key) : default_value(key)
        end
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :aboutUrl, :default, :propertyUrl, :valueUrl
          "string" unless value.is_a?(String)
        when :lang
          "valid BCP47 language tag" unless BCP47::Language.identify(value.to_s)
        when :null
          # To be valid, it must be a string or array
          "string or array of strings" unless !value.is_a?(Hash) && Array(value).all? {|v| v.is_a?(String)}
        when :ordered, :required
          "boolean" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :separator
          "string or null" unless value.nil? || value.is_a?(String)
        when :textDirection
          "rtl or ltr" unless %(rtl ltr).include?(value)
        when :datatype
          # We handle this through a separate datatype= setter
        end

        set_property(key, type, value, invalid)
      end
    end

    # Context used for this metadata. Use parent's if not defined on self.
    # @return [JSON::LD::Context]
    def context
      @context || (parent.context if parent)
    end

    def tables=(value)
      set_array_value(:tables, value, Table)
    end

    # An object property that provides a schema description as described in section 3.8 Schemas, for all the tables in the group. This may be provided as an embedded object within the JSON metadata or as a URL reference to a separate JSON schema document
    # when loading a remote schema, assign @id from it's location if not already set
    def tableSchema=(value)
      object[:tableSchema] = case value
      when String
        link = context.base.join(value).to_s
        md = Schema.open(link, **@options.merge(parent: self, context: nil, normalize: true))
        md[:@id] ||= link
        md
      when Hash
        Schema.new(value, **@options.merge(parent: self, context: nil))
      when Schema
        value
      else
        log_warn "#{type} has invalid property 'tableSchema' (#{value.inspect}): expected a URL or object"
        Schema.new({}, **@options.merge(parent: self, context: nil))
      end
    end

    def transformations=(value)
      set_array_value(:transformations, value, Metadata)
    end

    # Treat `dialect` similar to an inherited property, but merge together values from Table and TableGroup
    # @return [Dialect]
    def dialect
      @dialect ||= case
      when object[:dialect] then object[:dialect]
      when parent then parent.dialect
      when is_a?(Table) || is_a?(TableGroup)
        d = Dialect.new({}, **@options.merge(parent: self, context: nil))
        self.dialect = d unless self.parent
        d
      else
        raise Error, "Can't access dialect from #{self.class} without a parent"
      end
    end

    # Set new dialect
    # @return [Dialect]
    def dialect=(value)
      # Clear cached dialect information from children
      object.values.each do |v|
        case v
        when Metadata then v.object.delete(:dialect)
        when Array then v.each {|vv| vv.object.delete(:dialect) if vv.is_a?(Metadata)}
        end
      end

      # If provided, dialect provides hints to processors about how to parse the referenced file to create a tabular data model.
      @dialect = object[:dialect] = case value
      when String
        link = context.base.join(value).to_s
        md = Metadata.open(link, **@options.merge(parent: self, context: nil, normalize: true))
        md[:@id] ||= link
        md
      when Hash
        Dialect.new(value, **@options.merge(parent: self, context: nil))
      when Dialect
        value
      else
        log_warn "#{type} has invalid property 'dialect' (#{value.inspect}): expected a URL or object"
        nil
      end
    end

    # Set new datatype
    # @return [Dialect]
    # @raise [Error] if datatype is not valid
    def datatype=(value)
      val = case value
      when Hash then Datatype.new(value, **@options.merge(parent: self))
      else           Datatype.new({base: value}, **@options.merge(parent: self))
      end

      if val.valid? || value.is_a?(Hash)
        # Set it if it was specified as an object, which may cause validation errors later
        object[:datatype] = val
      else
        log_warn "#{type} has invalid property 'datatype': expected a built-in or an object"
      end
    end

    # Type of this Metadata
    # @return [:TableGroup, :Table, :Template, :Schema, :Column]
    def type; self.class.name.split('::').last.to_sym; end

    # Base URL of metadata
    # @return [RDF::URI]
    def base; @options[:base]; end

    ##
    # Do we have valid metadata?
    def valid?
      validate # Possibly re-validate
      !log_statistics[:error]
    end

    def validate!
      raise Error, "Metadata error" unless valid?
    end

    ##
    # Validate metadata and content, raising an error containing all errors detected during validation
    # @raise [Error] Raise error if metadata has any unexpected properties
    # @return [self]
    def validate
      expected_props, required_props = @properties.keys, @required

      unless is_a?(Dialect) || is_a?(Transformation)
        expected_props = expected_props + INHERITED_PROPERTIES.keys
      end

      # It has only expected properties (exclude metadata)
      check_keys = object.keys - [:"@id", :"@context"]
      check_keys = check_keys.reject {|k| k.to_s.include?(':')} unless is_a?(Dialect)
      log_warn "#{type} has unexpected keys: #{(check_keys - expected_props).map(&:to_s)}" unless check_keys.all? {|k| expected_props.include?(k)}

      # It has required properties
      log_error "#{type} missing required keys: #{(required_props - check_keys).map(&:to_s)}"  unless (required_props & check_keys) == required_props

      self.normalize!

      # Every property is valid
      object.keys.each do |key|
        value = object[key]
        case key
        when :base
          log_error "#{type} has invalid base: #{value.inspect}" unless DATATYPES.keys.map(&:to_s).include?(value)
        when :columns
          value.each do |col|
            col.validate
            log_statistics.merge!(col.log_statistics)
          end
          column_names = value.map(&:name)
          log_error "#{type} has invalid property '#{key}': must have unique names: #{column_names.inspect}" unless column_names.uniq == column_names
        when :datatype, :dialect, :tables, :tableSchema, :transformations
          Array(value).each do |t|
            # Make sure value is of appropriate class
            if t.is_a?({datatype: Datatype, dialect: Dialect, tables: Table, tableSchema: Schema, transformations: Transformation}[key])
              t.validate
              log_statistics.merge!(t.log_statistics)
            else
              log_error "#{type} has invalid property '#{key}': unexpected value #{value.class.name}"
            end
          end
          log_error "#{type} has invalid property 'tables': must not be empty" if key == :tables && Array(value).empty?
        when :foreignKeys
          # An array of foreign key definitions that define how the values from specified columns within this table link to rows within this table or other tables. A foreign key definition is a JSON object with the properties:
          value.each do |fk|
            columnReference, reference = fk['columnReference'], fk['reference']
            log_error "#{type} has invalid property '#{key}': missing columnReference and reference" unless columnReference && reference
            log_error "#{type} has invalid property '#{key}': has extra entries #{fk.keys.inspect}" unless fk.keys.length == 2

            # Verify that columns exist in this schema
            log_error "#{type} has invalid property '#{key}': no columnReference found" unless Array(columnReference).length > 0
            Array(columnReference).each do |k|
              log_error "#{type} has invalid property '#{key}': columnReference not found #{k}" unless self.columns.any? {|c| c[:name] == k}
            end

            if reference.is_a?(Hash)
              log_error "#{type} has invalid property '#{key}': reference has extra entries #{reference.keys.inspect}" unless (reference.keys - %w(resource schemaReference columnReference)).empty?
              ref_cols = reference['columnReference']
              schema = if reference.has_key?('resource')
                if reference.has_key?('schemaReference')
                  log_error "#{type} has invalid property '#{key}': reference has a schemaReference: #{reference.inspect}" 
                end
                # resource is the URL of a Table in the TableGroup
                ref = context.base.join(reference['resource']).to_s
                table = root.is_a?(TableGroup) && Array(root.tables).detect {|t| t.url == ref}
                log_error "#{type} has invalid property '#{key}': table referenced by #{ref} not found" unless table
                table.tableSchema if table
              elsif reference.has_key?('schemaReference')
                # resource is the @id of a Schema in the TableGroup
                ref = context.base.join(reference['schemaReference']).to_s
                tables = root.is_a?(TableGroup) ? root.tables.select {|t| t.tableSchema[:@id] == ref} : []
                case tables.length
                when 0
                  log_error "#{type} has invalid property '#{key}': schema referenced by #{ref} not found"
                  nil
                when 1
                  tables.first.tableSchema
                else
                  log_error "#{type} has invalid property '#{key}': multiple schemas found from #{ref}"
                  nil
                end
              end

              if schema
                # ref_cols must exist in schema
                log_error "#{type} has invalid property '#{key}': no columnReference found" unless Array(ref_cols).length > 0
                Array(ref_cols).each do |k|
                  log_error "#{type} has invalid property '#{key}': column reference not found #{k}" unless schema.columns.any? {|c| c[:name] == k}
                end
              end
            else
              log_error "#{type} has invalid property '#{key}': reference must be an object #{reference.inspect}"
            end
          end
        when :format
          case value
          when Hash
            # Object form only appropriate for numeric type
            unless %w(
              decimal integer long int short byte double float number
              nonNegativeInteger positiveInteger nonPositiveInteger negativeInteger
              unsignedLong unsignedInt unsignedShort unsignedByte
            ).include?(self.base)
              log_warn "#{type} has invalid property '#{key}': Object form only allowed on string or binary datatypes"
              object.delete(:format) # act as if not set
            end

            # Otherwise, if it exists, its a UAX35 number pattern
            begin
              parse_uax35_number(value["pattern"], nil, value.fetch('groupChar', ','), value.fetch('decimalChar', '.'))
            rescue ArgumentError => e
              log_warn "#{type} has invalid property '#{key}' pattern: #{e.message}"
              object[:format].delete("pattern") if object[:format] # act as if not set
            end
          else
            case self.base
            when 'boolean'
              unless value.split("|").length == 2
                log_warn "#{type} has invalid property '#{key}': annotation provides the true and false values expected, separated by '|'"
                object.delete(:format) # act as if not set
              end
            when :decimal, :integer, :long, :int, :short, :byte,
                 :nonNegativeInteger, :positiveInteger,
                 :unsignedLong, :unsignedInt, :unsignedShort, :unsignedByte,
                 :nonPositiveInteger, :negativeInteger,
                 :double, :float, :number
              begin
                parse_uax35_number(value, nil)
              rescue ArgumentError => e
                log_warn "#{type} has invalid property '#{key}': #{e.message}"
                object.delete(:format) # act as if not set
              end
            when 'date', 'dateTime', 'datetime', 'dateTimeStamp', 'time'
              # Parse and validate format
              begin
                parse_uax35_date(value, nil)
              rescue ArgumentError => e
                log_warn "#{type} has invalid property '#{key}': #{e.message}"
                object.delete(:format) # act as if not set
              end
            else
              # Otherwise, if it exists, its a regular expression
              begin
                Regexp.compile(value)
              rescue
                log_warn "#{type} has invalid property '#{key}': #{$!.message}"
                object.delete(:format) # act as if not set
              end
            end
          end
        when :length, :minLength, :maxLength
          # Applications must raise an error if both length and minLength are specified and length is less than minLength.
          # Similarly, applications must raise an error if both length and maxLength are specified and length is greater than maxLength.
          if object[:length]
            case key
            when :minLength
              log_error "#{type} has invalid property minLength': both length and minLength requires length be greater than or equal to minLength" if object[:length] < value
            when :maxLength
              log_error "#{type} has invalid property maxLength': both length and maxLength requires length be less than or equal to maxLength" if object[:length] > value
            end
          end

          # Applications must raise an error if minLength and maxLength are both specified and minLength is greater than maxLength.
          if key == :maxLength && object[:minLength]
            log_error "#{type} has invalid property #{key}': both minLength and maxLength requires minLength be less than or equal to maxLength" if object[:minLength] > value
          end

          # Applications must raise an error if length, maxLength, or minLength are specified and the base datatype is not string or one of its subtypes, or a binary type.
          unless %w(string normalizedString token language Name NMTOKEN hexBinary base64Binary binary).include?(self.base)
            log_error "#{type} has invalid property '#{key}': only allowed on string or binary datatypes"
          end
        when :minimum, :maximum, :minInclusive, :maxInclusive, :minExclusive, :maxExclusive
          case self.base
          when 'decimal', 'integer', 'long', 'int', 'short', 'byte', 'double', 'number', 'float',
               'nonNegativeInteger', 'positiveInteger', 'unsignedLong', 'unsignedInt', 'unsignedShort', 'unsignedByte',
               'nonPositiveInteger', 'negativeInteger', 'date', 'dateTime', 'datetime', 'dateTimeStamp', 'time',
               'duration', 'dayTimeDuration', 'yearMonthDuration'
            log_error "#{type} has invalid property '#{key}': #{value.to_ntriples} is not a valid #{self.base}" unless value.valid?

            case key
            when :minInclusive
              # Applications MUST raise an error if both minInclusive and minExclusive are specified
              log_error "#{type} cannot specify both minInclusive and minExclusive" if self.minExclusive

              # Applications MUST raise an error if both minInclusive and maxInclusive are specified and maxInclusive is less than minInclusive
              log_error "#{type} maxInclusive < minInclusive" if self.maxInclusive && self.maxInclusive < value

              # Applications MUST raise an error if both minInclusive and maxExclusive are specified and maxExclusive is less than or equal to minInclusive
              log_error "#{type} maxExclusive <= minInclusive" if self.maxExclusive && self.maxExclusive <= value
            when :maxInclusive
              # Applications MUST raise an error if both maxInclusive and maxExclusive are specified
              log_error "#{type} cannot specify both maInclusive and maxExclusive" if self.maxExclusive
            when :minExclusive
              # Applications MUST raise an error if both minExclusive and maxExclusive are specified and maxExclusive is less than minExclusive
              log_error "#{type} minExclusive < maxExclusive" if self.maxExclusive && self.maxExclusive < value

              # Applications MUST raise an error if both minExclusive and maxInclusive are specified and maxInclusive is less than or equal to minExclusive
              log_error "#{type} maxInclusive < minExclusive" if self.maxInclusive && self.maxInclusive <= value
            end
          else
            log_error "#{type} has invalid property '#{key}': only allowed on numeric, date/time or duration datatypes"
          end
        when :notes
          unless value.is_a?(Hash) || value.is_a?(Array)
            log_error "#{type} has invalid property '#{key}': #{value}, Object or Array"
          end
          begin
            normalize_jsonld(key, value)
          rescue Error => e
            log_error "#{type} has invalid content '#{key}': #{e.message}"
          end
        when :primaryKey, :rowTitles
          # A column reference property that holds either a single reference to a column description object or an array of references.
          "#{type} has invalid property '#{key}': no column references found" unless Array(value).length > 0
          Array(value).each do |k|
            unless self.columns.any? {|c| c[:name] == k}
              log_warn "#{type} has invalid property '#{key}': column reference not found #{k}"
              object.delete(key)
            end
          end
        when :@context
          # Skip these
        when :@id
          # Must not be a BNode
          if value.to_s.start_with?("_:")
            log_error "#{type} has invalid property '#{key}': #{value.inspect}, must not start with '_:'"
          end

          # Datatype @id MUST NOT be the URL of a built-in type
          if self.is_a?(Datatype) && DATATYPES.values.include?(value)
            log_error "#{type} has invalid property '#{key}': #{value.inspect}, must not be the URL of a built-in datatype"
          end
        when :@type
          # Must not be a BNode
          if value.to_s.start_with?("_:")
            log_error "#{type} has invalid property '@type': #{value.inspect}, must not start with '_:'"
          end
          case type
          when :Transformation
            log_error "#{type} has invalid property '@type': #{value.inspect}, expected #{type}" unless value.to_sym == :Template
          else
            log_error "#{type} has invalid property '@type': #{value.inspect}, expected #{type}" unless value.to_sym == type
          end
        when ->(k) {key.to_s.include?(':')}
          begin
            normalize_jsonld(key, value)
          rescue Error => e
            log_error "#{type} has invalid content '#{key}': #{e.message}"
          end
        end
      end

      self
    end

    ##
    # Determine if a natural language property is valid
    # @param [String, Array<String>, Hash{String => String}] value
    # @yield message error message
    # @return [String, nil]
    def valid_natural_language_property?(value)
      case value
      when String
      when Array
        "a valid natural language property" unless value.all? {|v| v.is_a?(String)}
      when Hash
        "a valid natural language property" if
          value.keys.any? {|k| k.to_s != "und" && !BCP47::Language.identify(k)} ||
          value.values.any? {|v| valid_natural_language_property?(v).is_a?(String)}
      else
        "a valid natural language property"
      end
    end

    ##
    # Yield each data row from the input file
    #
    # @param [:read] input
    # @yield [Row]
    def each_row(input)
      csv, number, skipped = nil, 0, 0
      path = input.base_uri.path rescue ""
      if path.end_with?('.html') || input.respond_to?(:content_type) && input.content_type == 'text/html'
        # Input is HTML; use fragment identfier to find table.
        fragment = RDF::URI(self.url).fragment rescue nil
        tab = begin
          # Extract with nokogiri
          require 'nokogiri' unless defined?(:Nokogiri)
          doc = Nokogiri::HTML.parse(input)
          doc.search("##{fragment}").first if fragment
        rescue LoadError
          # Extract with REXML
          # FIXME
        end

        raise Error, "Expected to find HTML table identified by fragment identifer ##{fragment}" unless tab

        # Use rows with <td> to create column data
        csv = []
        number = 0
        tab.xpath('.//tr').map do |row|
          number += 1 if row.xpath('th')
          data = row.xpath('td').map(&:content)
          csv << data unless data.empty?
        end
      else
        csv = ::CSV.new(input, **csv_options)
        # Skip skipRows and headerRowCount
        skipped = (dialect.skipRows.to_i + dialect.headerRowCount)
        (1..skipped).each {csv.shift}
      end
      csv.each do |data|
        # Check for embedded comments
        if dialect.commentPrefix && data.first.to_s.start_with?(dialect.commentPrefix)
          v = data.join(' ')[1..-1].strip
          unless v.empty?
            (self["rdfs:comment"] ||= []) << v
          end
          skipped += 1
          next
        elsif dialect.skipBlankRows && data.join("").strip.empty?
          skipped += 1
          next
        end
        number += 1
        row = Row.new(data, self, number, number + skipped, **@options)
        (self.object[:rows] ||= []) << row if @options[:validate] # Keep track of rows when validating
        yield(row)
      end
    end

    ##
    # Return JSON-friendly or yield RDF for common properties
    #
    # @overload common_properties(subject, property, value, &block)
    #   Yield RDF statements
    #   @param [RDF::Resource] subject
    #   @param [String] property
    #   @param [String, Hash{String => Object}, Array<String, Hash{String => Object}>] value
    #   @yield property, value
    #   @yieldparam [String] property as a PName or URL
    #   @yieldparam [RDF::Statement] statement
    #
    # @overload common_properties(subject, property, value)
    #   Return value with expanded values and node references flattened
    #   @return [String, Hash{String => Object}, Array<String, Hash{String => Object}>] simply extracted from metadata
    def common_properties(subject, property, value, &block)
      if block_given?
        property = context.expand_iri(property.to_s, vocab: true) unless property.is_a?(RDF::URI)
        case value
        when Array
          value.each {|v| common_properties(subject, property, v, &block)}
        when Hash
          if value['@value']
            dt = RDF::URI(context.expand_iri(value['@type'], vocab: true)) if value['@type']
            lit = RDF::Literal(value['@value'], language: value['@language'], datatype: dt)
            block.call(RDF::Statement(subject, property, lit))
          else
            # value MUST be a node object, establish a new subject from `@id`
            s2 = value.has_key?('@id') ? context.expand_iri(value['@id']) : RDF::Node.new

            # Generate a triple
            block.call(RDF::Statement(subject, property, s2))

            # Generate types
            Array(value['@type']).each do |t|
              block.call(RDF::Statement(s2, RDF.type, context.expand_iri(t, vocab: true)))
            end

            # Generate triples for all other properties
            value.each do |prop, val|
              next if prop.to_s.start_with?('@')
              common_properties(s2, prop, val, &block)
            end
          end
        else
          # Value is a primitive JSON value
          lit = RDF::Literal(value)
          block.call(RDF::Statement(subject, property, RDF::Literal(value)))
        end
      else
        case value
        when Array
          value.map {|v| common_properties(subject, property, v)}
        when Hash
          if value['@value']
            value['@value']
          elsif value.keys == %w(@id) && value['@id']
            value['@id']
          else
            nv = {}
            value.each do |k, v|
              case k.to_s
              when '@id' then nv[k.to_s] = context.expand_iri(v['@id']).to_s
              when '@type' then nv[k.to_s] = v
              else nv[k.to_s] = common_properties(nil, k, v)
              end
            end
            nv
          end
        else
          value
        end
      end
    end

    # Does the Metadata have any common properties?
    # @return [Boolean]
    def has_annotations?
      object.keys.any? {|k| k.to_s.include?(':')}
    end

    # Does this metadata describe the file (URL)?
    # @param [RDF::URL] url
    # @return [Boolean]
    def describes_file?(url)
      case self
      when TableGroup
        tables.any? {|t| t.url == url}
      else
        self.url == url
      end
    end

    # Verify that the metadata we're using is compatible with embedded metadata
    # @param [Table] other
    # @raise [Error] if not compatible
    def verify_compatible!(other)
      if self.is_a?(TableGroup)
        unless tables.any? {|t| t.url == other.url && t.verify_compatible!(other)}
          if @options[:validate]
            raise Error, "TableGroups must have Table with matching url #{tables.map(&:url).inspect} vs #{other.url.inspect}"
          else
            log_warn "TableGroups must have Table with matching url #{tables.map(&:url).inspect} vs #{other.url.inspect}"
          end
        end
      else
        # Tables must have the same url
        unless url == other.url
          if @options[:validate]
            raise Error, "Tables must have the same url: #{url.inspect} vs #{other.url.inspect}}"
          else
            log_warn "Tables must have the same url: #{url.inspect} vs #{other.url.inspect}}"
          end
        end

        # Each column description within B MUST match the corresponding column description in A for non-virtual columns
        non_virtual_columns = Array(tableSchema.columns).reject(&:virtual)
        object_columns = Array(other.tableSchema.columns)

        # Special case, if there is no header, then there are no column definitions, allow this as being compatible
        if non_virtual_columns.length != object_columns.length && !object_columns.empty?
          if @options[:validate]
            raise Error, "Columns must have the same number of non-virtual columns: #{non_virtual_columns.map(&:name).inspect} vs #{object_columns.map(&:name).inspect}"
          else
            log_warn "Columns must have the same number of non-virtual columns: #{non_virtual_columns.map(&:name).inspect} vs #{object_columns.map(&:name).inspect}"

            # If present, a virtual column MUST appear after all other non-virtual column definitions
            raise Error, "Virtual columns may not appear before non-virtual columns" unless Array(tableSchema.columns)[0..non_virtual_columns.length-1] == non_virtual_columns
            virtual_columns = Array(tableSchema.columns).select(&:virtual)
            while non_virtual_columns.length < object_columns.length
              non_virtual_columns << nil
            end

            # Create necessary column entries
            tableSchema.columns = non_virtual_columns + virtual_columns
          end
        end
        index = 0
        object_columns.all? do |cb|
          ca = non_virtual_columns[index] || Column.new({}, **@options)
          ta = ca.titles || {}
          tb = cb.titles || {}
          if !ca.object.has_key?(:name) && !cb.object.has_key?(:name) && ta.empty? && tb.empty?
            true
          elsif ca.object.has_key?(:name) && cb.object.has_key?(:name)
            raise Error, "Column #{index + 1} doesn't match on name: #{ca.name || 'no name'}, #{cb.name || 'no name'}" unless ca.name == cb.name
          elsif @options[:validate] || !ta.empty? && !tb.empty?
            # If validating, column compatibility requires strict match between titles
            titles_match = case
            when Array(ta['und']).any? {|t| tb.values.flatten.compact.include?(t)}
              true
            when Array(tb['und']).any? {|t| ta.values.flatten.compact.include?(t)}
              true
            when ta.any? {|lang, values| !(Array(tb[lang]) & Array(values)).empty?}
              # Match on title and language
              true
            else
              # Match if a language from ta is a prefix of a language from tb with matching titles
              ta.any? do |la, values|
                tb.keys.any? do |lb|
                  (la.start_with?(lb) || lb.start_with?(la)) && !(Array(tb[lb]) & Array(values)).empty?
                end
              end
            end

            if titles_match
              true
            elsif !@options[:validate]
              # If not validating, columns don't match, but processing continues
              log_warn "Column #{index + 1} doesn't match on titles: #{Array(ta['und']).join(',').inspect} vs #{Array(tb['und']).join(',').inspect}"
              true
            else
              raise Error, "Column #{index + 1} doesn't match on titles: #{Array(ta['und']).join(',').inspect} vs #{Array(tb['und']).join(',').inspect}"
            end
          end
          index += 1
        end
      end
      true
    end

    def inspect
      self.class.name + (respond_to?(:to_atd) ? to_atd : object).inspect
    end

    # Proxy to @object
    def [](key); object[key]; end
    def []=(key, value); object[key] = value; end
    def each(&block); object.each(&block); end
    def ==(other)
      object == (other.is_a?(Hash) ? other : (other.respond_to?(:object) ? other.object : other))
    end
    def to_json(args=nil); object.to_json(args); end

    ##
    # Normalize object
    # @raise [Error]
    # @return [self]
    def normalize!
      self.each do |key, value|
        self[key] = case @properties[key] || INHERITED_PROPERTIES[key]
        when ->(k) {key.to_s.include?(':') || key == :notes}
          normalize_jsonld(key, value)
        when ->(k) {key.to_s == '@context'}
          "http://www.w3.org/ns/csvw"
        when :array
          value = [value] unless value.is_a?(Array)
          value.map do |v|
            if v.is_a?(Metadata)
              v.normalize!
            elsif v.is_a?(Hash) && (ref = v["reference"]).is_a?(Hash)
              # SPEC SUGGESTION: special case for foreignKeys
              ref["resource"] = context.base.join(ref["resource"]).to_s if ref["resource"]
              ref["schemaReference"] = context.base.join(ref["schemaReference"]).to_s if ref["schemaReference"]
              v
            else
              v
            end
          end
        when :link
          context.base.join(value).to_s
        when :object
          case value
          when Metadata then value.normalize!
          when String
            # Load referenced JSON document
            # (This is done when objects are loaded in this implementation)
            raise "unexpected String value of property '#{key}': #{value}"
          else value
          end
        when :natural_language
          value.is_a?(Hash) ? value : {(context.default_language || 'und') => Array(value)}
        when :atomic
          case key
          when :minimum, :maximum, :minInclusive, :maxInclusive, :minExclusive, :maxExclusive
            # Convert to a typed literal based on `base`. This will be validated later
            RDF::Literal(value, datatype: DATATYPES[self.base.to_sym])
          else
            value
          end
        else
          value
        end
      end
      self
    end

    ##
    # Normalize JSON-LD
    #
    # Also, raise error if invalid JSON-LD dialect is detected
    #
    # @param [Symbol, String] property
    # @param [String, Hash{String => Object}, Array<String, Hash{String => Object}>] value
    # @return [String, Hash{String => Object}, Array<String, Hash{String => Object}>]
    def normalize_jsonld(property, value)
      case value
      when Array
        value.map {|v| normalize_jsonld(property, v)}
      when String
        ev = {'@value' => value}
        ev['@language'] = context.default_language if context.default_language
        ev
      when Hash
        if value['@value']
          if !(value.keys.sort - %w(@value @type @language)).empty?
            log_error "Value object may not contain keys other than @value, @type, or @language: #{value.to_json}"
          elsif (value.keys.sort & %w(@language @type)) == %w(@language @type)
            log_error "Value object may not contain both @type and @language: #{value.to_json}"
          elsif value['@language'] && !BCP47::Language.identify(value['@language'].to_s)
            log_error "Value object with @language must use valid language: #{value.to_json}"
          elsif value['@type'] && (value['@type'].start_with?('_:') || !context.expand_iri(value['@type'], vocab: true).absolute?)
            log_error "Value object with @type must defined type: #{value.to_json}"
          end
          value
        else
          nv = {}
          value.each do |k, v|
            case k
            when "@id"
              nv[k] = context.expand_iri(v, documentRelative: true).to_s
              log_error "Invalid use of explicit BNode on @id" if nv[k].start_with?('_:')
            when "@type"
              Array(v).each do |vv|
                # Validate that all type values transform to absolute IRIs
                resource = context.expand_iri(vv, vocab: true)
                log_error "Invalid type #{vv} in JSON-LD context" unless resource.is_a?(RDF::URI) && resource.absolute?
              end
              nv[k] = v
            when /^(@|_:)/
              log_error "Invalid use of #{k} in JSON-LD content"
            else
              nv[k] = normalize_jsonld(k, v)
            end
          end
          nv
        end
      else
        value
      end
    end
  protected

    def set_property(key, type, value, invalid)
      if invalid
        log_warn "#{type} has invalid property '#{key}' (#{value.inspect}): expected #{invalid}"
        case type
        when :link, :uri_template
          object[key] = ""
        when :object
          object[key] = {}
        when :natural_language
          object[key] = set_nl(value) || []
        else
          object.delete(key)
        end
      else
        object[key] = value
      end
    end

    # When setting a natural language property, always put in language-map form
    # @param [Hash{String => String, Array<String>}, Array<String>, String] value
    # @return [Hash{String => Array<String>}]
    def set_nl(value)
      case value
      when String then value
      when Array then value.select {|v| v.is_a?(String)}
      when Hash
        value.delete_if {|k, v| !BCP47::Language.identify(k)}
        value.each do |k, v|
          value[k] = Array(v).select {|vv| vv.is_a?(String)}
        end
      else nil
      end
    end

    # General setter for array properties
    def set_array_value(key, value, klass, **options)
      object[key] = case value
      when Array
        value.map do |v|
          case v
          when Hash
            klass.new(v, **@options.merge(options).merge(parent: self, context: nil))
          else v
          end
        end
      else
        log_warn "#{type} has invalid property '#{key}': expected array of #{klass}"
        []
      end

      unless object[key].all? {|v| v.is_a?(klass)}
        log_warn "#{type} has invalid property '#{key}': expected array of #{klass}"
        # Remove elements that aren't of the right types
        object[key] = object[key].select! {|v| v.is_a?(klass)}
      end
    end

    def default_value(prop)
      self.class.const_get(:DEFAULTS).merge(INHERITED_DEFAULTS)[prop]
    end

    ##
    # Get the root metadata object
    # @return [TableGroup, Table]
    def root
      self.parent ? self.parent.root : self
    end
  private
    # Options passed to CSV.new based on dialect
    # @todo lineTerminators is ignored, as CSV parser uses single string or `:auto`
    def csv_options
      {
        col_sep: (is_a?(Dialect) ? self : dialect).delimiter,
        #row_sep: Array((is_a?(Dialect) ? self : dialect).lineTerminators).first,
        quote_char: (is_a?(Dialect) ? self : dialect).quoteChar,
        encoding: (is_a?(Dialect) ? self : dialect).encoding
      }
    end

    class DebugContext
      include RDF::Util::Logger
    end
    def self.log_debug(*args, **options, &block)
      DebugContext.new.log_debug(*args, **options, &block)
    end
    def self.log_warn(*args, **options)
      DebugContext.new.log_warn(*args, **options)
    end
  end

  class TableGroup < Metadata
    PROPERTIES = {
      :@id              => :link,
      :@type            => :atomic,
      notes:               :array,
      tables:              :array,
      tableSchema:         :object,
      tableDirection:      :atomic,
      dialect:             :object,
      transformations:     :array,
    }.freeze
    DEFAULTS = {
      tableDirection:      "auto".freeze,
    }.freeze
    REQUIRED = [:tables].freeze

    # Getters and Setters
    PROPERTIES.each do |key, type|
      next if [:dialect].include?(key)

      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      next if [:tables, :tableSchema, :transformations].include?(key)
      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :tableDirection
          "rtl, ltr, or auto" unless %(rtl ltr auto).include?(value)
        when :notes, :tables, :tableSchema, :dialect, :transformations
          # We handle this through a separate setters
        end

        set_property(key, type, value, invalid)
      end
    end

    # Does the Metadata or any descendant have any common properties
    # @return [Boolean]
    def has_annotations?
      super || tables.any? {|t| t.has_annotations? }
    end

    ##
    # Iterate over all tables
    # @yield [Table]
    def each_table
      tables.map(&:url).each do |url|
        yield for_table(url)
      end
    end

    ##
    # Return the metadata for a specific table, re-basing context as necessary
    #
    # @param [String] url of the table
    # @return [Table]
    def for_table(url)
      # If there are no tables, assume there's one for this table
      #self.tables ||= [Table.new(url: url)]
      if table = Array(tables).detect {|t| t.url == url}
        # Set document base for this table for resolving URLs
        table.instance_variable_set(:@context, context.dup)
        table.context.base = url
        table
      end
    end

    # Return Annotated Table Group representation
    def to_atd
      object.inject({
        "@id" => (id.to_s if id),
        "@type" => "AnnotatedTableGroup",
        "tables" => Array(self.tables).map(&:to_atd)
      }) do |memo, (k, v)|
        memo[k.to_s] ||= v
        memo
      end.delete_if {|k,v| v.nil? || v.is_a?(Metadata) || k.to_s == "@context"}
    end
  end

  class Table < Metadata
    PROPERTIES = {
      :@id              => :link,
      :@type            => :atomic,
      dialect:             :object,
      notes:               :array,
      suppressOutput:      :atomic,
      tableDirection:      :atomic,
      tableSchema:         :object,
      transformations:     :array,
      url:                 :link,
    }.freeze
    DEFAULTS = {
      suppressOutput:      false,
      tableDirection:      "auto".freeze,
    }.freeze
    REQUIRED = [:url].freeze

    # Getters and Setters
    PROPERTIES.each do |key, type|
      next if [:dialect, :url].include?(key)
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      next if [:tableSchema, :transformations].include?(key)
      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :suppressOutput
          "boolean true or false" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :tableDirection
          "rtl, ltr, or auto" unless %(rtl ltr auto).include?(value)
        when :url
          "valid URL" unless value.is_a?(String) && context.base.join(value).valid?
        when :notes, :tableSchema, :dialect, :transformations
          # We handle this through a separate setters
        end

        if invalid
          set_property(key, type, value, invalid)
        elsif key == :url
          # URL of CSV relative to metadata
          object[:url] = value
          @url = context.base.join(value)
          @context.base = @url if @context # Use as base for expanding IRIs
        else
          object[key] = value
        end
      end
    end

    # Does the Metadata or any descendant have any common properties
    # @return [Boolean]
    def has_annotations?
      super || tableSchema && tableSchema.has_annotations?
    end

    # Return a new TableGroup based on this Table
    def to_table_group
      content = {"@type" => "TableGroup", "tables" => [self]}
      content['@context'] = object.delete(:@context) if object[:@context]
      ctx = @context
      remove_instance_variable(:@context) if instance_variables.include?(:@context)
      tg = TableGroup.new(content, **@options.merge(context: ctx, filenames: @filenames, base: base))
      @parent = tg  # Link from parent
      tg
    end

    # Return Annotated Table representation
    def to_atd
      object.inject({
        "@id" => (id.to_s if id),
        "@type" => "AnnotatedTable",
        "url" => self.url.to_s,
        "tableSchema" => (tableSchema.to_atd if tableSchema),
      }) do |memo, (k, v)|
        memo[k.to_s] ||= v
        memo
      end.delete_if {|k,v| v.nil? || v.is_a?(Metadata) || k.to_s == "@context"}
    end
  end

  class Schema < Metadata
    PROPERTIES = {
      :@id       => :link,
      :@type     => :atomic,
      columns:      :array,
      foreignKeys:  :array,
      primaryKey:   :column_reference,
      rowTitles:    :column_reference,
    }.freeze
    DEFAULTS = {}.freeze
    REQUIRED = [].freeze

    # Getters and Setters
    PROPERTIES.each do |key, type|
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :primaryKey, :rowTitles
          "string or array of strings" unless !value.is_a?(Hash) && Array(value).all? {|v| v.is_a?(String)}
        end

        set_property(key, type, value, invalid)
      end
    end

    def columns=(value)
      object[:columns] = case value
      when Array
        number = 0
        value.map do |v|
          number += 1
          case v
          when Hash
            Column.new(v, **@options.merge(
              table: (parent if parent.is_a?(Table)),
              parent: self,
              context: nil,
              number: number))
          else
            v
          end
        end
      else
        log_warn "#{type} has invalid property 'columns': expected array of Column"
        []
      end

      unless object[:columns].all? {|v| v.is_a?(Column)}
        log_warn "#{type} has invalid property 'columns': expected array of Column"
        # Remove elements that aren't of the right types
        object[:columns] = object[:columns].select! {|v| v.is_a?(Column)}
      end
    end

    def foreignKeys=(value)
      object[:foreignKeys] = case value
      when Array then value
      else
        log_warn "#{type} has invalid property 'foreignKeys': expected array of ForeignKey"
        []
      end

      unless object[:foreignKeys].all? {|v| v.is_a?(Hash)}
        log_warn "#{type} has invalid property 'foreignKeys': expected array of ForeignKey"
        # Remove elements that aren't of the right types
        object[:foreignKeys] = object[:foreignKeys].select! {|v| v.is_a?(Hash)}
      end
    end

    ##
    # List of foreign keys referencing the specified table
    #
    # @param [Table] table
    # @return [Array<Hash>]
    def foreign_keys_referencing(table)
      Array(foreignKeys).select do |fk|
        reference = fk['reference']
        if reference['resource']
          ref = context.base.join(reference['resource']).to_s
          table.url == ref
        else # schemaReference
          ref = context.base.join(reference['schemaReference']).to_s
          table.tableSchema.id == ref
        end
      end
    end

    # Return Annotated Table representation
    def to_atd
      object.inject({
        "@id" => (id.to_s if id),
        "@type" => "Schema",
        "columns" => Array(columns).map(&:to_atd),
      }) do |memo, (k, v)|
        memo[k.to_s] ||= v
        memo
      end.delete_if {|k,v| v.nil? || v.is_a?(Metadata)}
    end
  end

  class Column < Metadata
    PROPERTIES = {
      :@id         => :link,
      :@type       => :atomic,
      name:           :atomic,
      suppressOutput: :atomic,
      titles:         :natural_language,
      virtual:        :atomic,
    }.freeze
    DEFAULTS = {
      suppressOutput:      false,
      virtual:             false,
    }.freeze
    REQUIRED = [].freeze

    ##
    # Table containing this column (if any)
    # @return [Table]
    def table; @options[:table]; end

    # Column number set on initialization
    # @return [Integer] 1-based colnum number
    def number
      @options.fetch(:number, 0)
    end

    # Source Column number set on initialization
    #
    # @note this is lazy evaluated to avoid dependencies on setting dialect vs. initializing columns
    # @return [Integer] 1-based colnum number
    def sourceNumber
      skipColumns = table ? dialect.skipColumns.to_i : 0
      number + skipColumns
    end

    # Does the Metadata or any descendant have any common properties
    # @return [Boolean]
    def has_annotations?
      super || columns.any? {|c| c.has_annotations? }
    end

    # Getters and Setters
    PROPERTIES.each do |key, t|
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :name
          "proper name format" unless value.is_a?(String) && value.match(NAME_SYNTAX)
        when :suppressOutput, :virtual
          "boolean true or false" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :titles
          valid_natural_language_property?(value)
        end

        set_property(key, t, value, invalid)
      end
    end

    # Return or create a name for the column from titles, if it exists
    def name
      self[:name] || if titles && (ts = titles[context.default_language || 'und'] || titles[self.lang || 'und'])
        n = Array(ts).first
        n0 = RDF::URI.encode(n[0,1], /[^a-zA-Z0-9]/).encode("utf-8")
        n1 = RDF::URI.encode(n[1..-1], /[^\w\.]/).encode("utf-8")
        "#{n0}#{n1}"
      end || "_col.#{number}"
    end

    # Identifier for this Column, as an RFC7111 fragment 
    # @return [RDF::URI]
    def id;
      url = table ? table.url : RDF::URI("")
      url.to_s + "#col=#{self.sourceNumber}";
    end

    # Return Annotated Column representation
    def to_atd
      object.inject({
        "@id" => id.to_s,
        "@type" => "Column",
        "table" => (table.id.to_s if table.id),
        "number" => self.number,
        "sourceNumber" => self.sourceNumber,
        "virtual" => self.virtual,
        "name" => self.name,
        "titles" => self.titles
      }) do |memo, (k, v)|
        memo[k.to_s] ||= v
        memo
      end.delete_if {|k,v| v.nil?}
    end
  end

  class Transformation < Metadata
    PROPERTIES = {
      :@id         => :link,
      :@type       => :atomic,
      source:         :atomic,
      targetFormat:   :link,
      scriptFormat:   :link,
      titles:         :natural_language,
      url:            :link,
    }.freeze
    DEFAULTS = {}.freeze
    REQUIRED = %w(url targetFormat scriptFormat).map(&:to_sym).freeze

    # Type of this Metadata
    # @return [:Template]
    def type; :Template; end

    # Getters and Setters
    PROPERTIES.each do |key, type|
      next if [:url].include?(key)
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :scriptFormat, :targetFormat
          "valid absolute URL" unless RDF::URI(value).valid?
        when :source
          "json or rdf" unless %w(json rdf).include?(value) || value.nil?
        end

        set_property(key, type, value, invalid)
      end
    end
  end

  class Dialect < Metadata
    # Defaults for dialects
    DEFAULTS = {
      commentPrefix:      false,
      delimiter:          ",".freeze,
      doubleQuote:        true,
      encoding:           "utf-8".freeze,
      header:             true,
      headerRowCount:     1,
      lineTerminators:    :auto,
      quoteChar:          '"'.freeze,
      skipBlankRows:      false,
      skipColumns:        0,
      skipInitialSpace:   false,
      skipRows:           0,
      trim:               true
    }.freeze

    PROPERTIES = {
      :@id             => :link,
      :@type           => :atomic,
      commentPrefix:      :atomic,
      delimiter:          :atomic,
      doubleQuote:        :atomic,
      encoding:           :atomic,
      header:             :atomic,
      headerRowCount:     :atomic,
      lineTerminators:    :atomic,
      quoteChar:          :atomic,
      skipBlankRows:      :atomic,
      skipColumns:        :atomic,
      skipInitialSpace:   :atomic,
      skipRows:           :atomic,
      trim:               :atomic,
    }.freeze

    REQUIRED = [].freeze

    # Getters and Setters
    PROPERTIES.each do |key, type|
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :commentPrefix, :delimiter, :quoteChar
          "a string" unless value.is_a?(String)
        when :lineTerminators
          "a string or array of strings" unless Array(value).all? {|e| e.is_a?(String)}
        when :doubleQuote, :header, :skipInitialSpace, :skipBlankRows
          "boolean true or false" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :encoding
          "a valid encoding" unless (Encoding.find(value) rescue false)
        when :headerRowCount, :skipColumns, :skipRows
          "a non-negative integer" unless value.is_a?(Numeric) && value.integer? && value >= 0
        when :trim
          "true, false, start or end" unless %w(true false start end).include?(value.to_s.downcase)
        when :titles
          valid_natural_language_property?(value)
        end

        set_property(key, type, value, invalid)
      end
    end

    # escape character
    # @return [String]
    def escape_character
      self.doubleQuote ? '"' : '\\'
    end

    # default for headerRowCount is zero if header is false
    # @return [Integer]
    def headerRowCount
      object.fetch(:headerRowCount, self.header ? 1 : 0)
    end

    # default for trim comes from skipInitialSpace
    # @return [Boolean, String]
    def trim
      object.fetch(:trim, self.skipInitialSpace ? 'start' : true)
    end

    ##
    # Extract a new Metadata document from the file or data provided
    #
    # @param [#read, #to_s] input IO, or file path or URL
    # @param [Table] metadata used for saving annotations created while extracting metadata
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Util::File.open_file`)
    # @option options [String] :lang, language to set in table, if any
    # @return [Metadata] Tabular metadata
    # @see http://w3c.github.io/csvw/syntax/#parsing
    def embedded_metadata(input, metadata, **options)
      options = options.dup
      options.delete(:context) # Don't accidentally use a passed context
      # Normalize input to an IO object
      if input.is_a?(String)
        return ::RDF::Util::File.open_file(input) {|f| embedded_metadata(f, metadata, **options.merge(base: input.to_s))}
      end

      table = {
        "@context" => "http://www.w3.org/ns/csvw",
        "url" => (options.fetch(:base, "")),
        "@type" => "Table",
        "tableSchema" => {
          "@type" => "Schema",
          "columns" => []
        }
      }
      metadata ||= table  # In case the embedded metadata becomes the final metadata
      lang = metadata["lang"] = options[:lang] if options[:lang]
      lang ||= 'und'

      # Set encoding on input
      path = input.base_uri.path rescue ""
      if path.end_with?('.html') || input.respond_to?(:content_type) && input.content_type == 'text/html'
        # Input is HTML; use fragment identfier to find table.
        fragment = RDF::URI(table["url"]).fragment rescue nil
        tab = begin
          # Extract with nokogiri
          require 'nokogiri' unless defined?(:Nokogiri)
          doc = Nokogiri::HTML.parse(input)
          doc.search("##{fragment}").first if fragment
        rescue LoadError
          # Extract with REXML
          # FIXME
        end

        raise Error, "Expected to find HTML table identified by fragment identifer ##{fragment}" unless tab

        # Use rows with <th> to create column titles
        tab.xpath('.//tr').each do |row|
          row.xpath('th').map(&:content).each_with_index do |value, index|
            # Skip columns
            skipCols = skipColumns.to_i
            next if index < skipCols || value.to_s.empty?

            # Trim value
            value.lstrip! if %w(true start).include?(trim.to_s)
            value.rstrip! if %w(true end).include?(trim.to_s)

            # Initialize titles
            columns = table["tableSchema"]["columns"] ||= []
            column = columns[index - skipCols] ||= {
              "titles" => {lang => []},
            }
            column["titles"][lang] << value if value
          end
        end
      else
        csv = ::CSV.new(input, **csv_options)
        (1..skipRows.to_i).each do
          value = csv.shift.join(delimiter)  # Skip initial lines, these form comment annotations
          # Trim value
          value.lstrip! if %w(true start).include?(trim.to_s)
          value.rstrip! if %w(true end).include?(trim.to_s)

          value = value[1..-1].strip if commentPrefix && value.start_with?(commentPrefix)
          (metadata["rdfs:comment"] ||= []) << value unless value.empty?
        end
        log_debug("embedded_metadata") {"notes: #{table["notes"].inspect}"}

        (1..headerRowCount).each do
          row_data = Array(csv.shift)
          Array(row_data).each_with_index do |value, index|
            # Skip columns
            skipCols = skipColumns.to_i
            next if index < skipCols || value.to_s.empty?

            # Trim value
            value.lstrip! if %w(true start).include?(trim.to_s)
            value.rstrip! if %w(true end).include?(trim.to_s)

            # Initialize titles
            columns = table["tableSchema"]["columns"] ||= []
            column = columns[index - skipCols] ||= {
              "titles" => {lang => []},
            }
            column["titles"][lang] << value
          end
        end
      end
      log_debug("embedded_metadata") {"table: #{table.inspect}"}
      input.rewind if input.respond_to?(:rewind)

      Table.new(table, **options.merge(reason: "load embedded metadata: #{table['@id']}"))
    end
  end

  class Datatype < Metadata
    include UAX35

    PROPERTIES = {
      :@id       => :link,
      :@type     => :atomic,
      base:         :atomic,
      format:       :atomic,
      length:       :atomic,
      minLength:    :atomic,
      maxLength:    :atomic,
      minimum:      :atomic,
      maximum:      :atomic,
      minInclusive: :atomic,
      maxInclusive: :atomic,
      minExclusive: :atomic,
      maxExclusive: :atomic,
    }.freeze
    REQUIRED = [].freeze
    DEFAULTS = {
      base: "string"
    }.freeze

    # Override `base` in Metadata
    def base; object[:base]; end

    # Getters and Setters
    PROPERTIES.each do |key, type|
      define_method(key) do
        object.fetch(key, DEFAULTS[key])
      end

      define_method("#{key}=".to_sym) do |value|
        invalid = case key
        when :base
          "built-in datatype" unless DATATYPES.keys.map(&:to_s).include?(value)
        when :minimum, :maximum, :minInclusive, :maxInclusive, :minExclusive, :maxExclusive
          "numeric or valid date/time" unless value.is_a?(Numeric) ||
            RDF::Literal::Date.new(value.to_s).valid? ||
            RDF::Literal::Time.new(value.to_s).valid? ||
            RDF::Literal::DateTime.new(value.to_s).valid?
        when :format
          case value
          when String
            nil
          when Hash
            unless (value.keys.map(&:to_s) - %w(groupChar decimalChar pattern)).empty?
              "an object containing only groupChar, decimalChar, and/or pattern"
            end
          else
            "a string or object"
          end
        when :length, :minLength, :maxLength
          if !(value.is_a?(Numeric) && value.integer? && value >= 0)
            "a non-negative integer" 
          end
        end

        set_property(key, type, value, invalid)
      end
    end
  end

  # Wraps each resulting row
  class Row
    # Class for returning values
    Cell = Struct.new(:table, :column, :row, :stringValue, :aboutUrl, :propertyUrl, :valueUrl, :value, :errors) do
      def set_urls(mapped_values, decode_uri)
        %w(aboutUrl propertyUrl valueUrl).each do |prop|
          # If the cell value is nil, and it is not a virtual column
          next if prop == "valueUrl" && value.nil? && !column.virtual
          if v = column.send(prop.to_sym)
            t = Addressable::Template.new(v)
            mapped = t.expand(mapped_values).to_s
            mapped = RDF::URI.decode(mapped) if decode_uri
            # FIXME: don't expand here, do it in CSV2RDF
            url = row.context.expand_iri(mapped, documentRelative: true)
            self.send("#{prop}=".to_sym, url)
          end
        end
      end

      def valid?; Array(errors).empty?; end
      def to_s; value.to_s; end

      # Identifier for this Cell, as an RFC7111 fragment 
      # @return [RDF::URI]
      def id; table.url + "#cell=#{self.row.sourceNumber},#{self.column.sourceNumber}"; end

      # Return Annotated Cell representation
      def to_atd
        {
          "@id" => id.to_s,
          "@type" => "Cell",
          "column" => column.id.to_s,
          "row" => row.id.to_s,
          "stringValue" => self.stringValue,
          "table" => (table.id.to_s if table.id),
          "value" => table.context.expand_value(nil, self.value),
          "errors" => self.errors
        }.delete_if {|k,v| Array(v).empty?}
      end

      def inspect
        self.class.name + to_atd.inspect
      end
    end

    # Row values, hashed by `name`
    attr_reader :values

    # Row number of this row
    # @return [Integer]
    attr_reader :number

    # Row number of this row from the original source
    # @return [Integer]
    attr_reader :sourceNumber

    #
    # Table containing this row
    # @return [Table]
    attr_reader :table

    #
    # Cells providing a unique row identifier
    # @return [Array<Cell>]
    attr_reader :primaryKey

    #
    # Title(s) of this row
    # @return [Array<RDF::Literal>]
    attr_reader :titles

    #
    # Context from Table with base set to table URL for expanding URI Templates
    # @return [JSON::LD::Context]
    attr_reader :context

    ##
    # @param [Array<Array<String>>] row
    # @param [Metadata] metadata for Table
    # @param [Integer] number 1-based row number after skipped/header rows
    # @param [Integer] source_number 1-based row number from source
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Boolean] :validate check for PK/FK consistency
    # @return [Row]
    def initialize(row, metadata, number, source_number, **options)
      @table = metadata
      @number = number
      @sourceNumber = source_number
      @values = []
      skipColumns = metadata.dialect.skipColumns.to_i

      @context = table.context.dup
      @context.base = table.url

      # Create values hash
      # SPEC CONFUSION: are values pre-or-post conversion?
      map_values = {"_row" => number, "_sourceRow" => source_number}

      columns = metadata.tableSchema.columns ||= []
      non_virtual_columns = columns.reject(&:virtual)

      if row.length < non_virtual_columns.length
        raise Error, "Row #{source_number} has #{row.length} columns, expected #{non_virtual_columns.length}"
      end

      # Make sure that the row length is at least as long as the number of column definitions, to implicitly include virtual columns
      columns.each_with_index {|c, index| row[index] ||= c.null}

      row.each_with_index do |value, index|

        next if index < skipColumns

        cell_errors = []

        # create column if necessary
        columns[index - skipColumns] ||=
          Column.new({}, **options.merge(table: metadata, parent: metadata.tableSchema, number: index + 1 - skipColumns))

        column = columns[index - skipColumns]

        @values << cell = Cell.new(metadata, column, self, value)

        datatype = column.datatype || Datatype.new({base: "string"}, **options.merge(parent: column))
        value = value.gsub(/\r\n\t/, ' ') unless %w(string json xml html anyAtomicType).include?(datatype.base)
        value = value.strip.gsub(/\s+/, ' ') unless %w(string json xml html anyAtomicType normalizedString).include?(datatype.base)
        # if the resulting string is an empty string, apply the remaining steps to the string given by the default property
        value = column.default || '' if value.empty?

        cell_values = column.separator ? value.split(column.separator) : [value]

        cell_values = cell_values.map do |v|
          v = v.strip unless %w(string anyAtomicType).include?(datatype.base)
          v = column.default || '' if v.empty?
          if Array(column.null).include?(v)
            nil
          else
            expanded_dt = datatype.id || metadata.context.expand_iri(datatype.base, vocab: true)
            if (lit_or_errors = value_matching_datatype(v.dup, datatype, expanded_dt, column.lang)).is_a?(RDF::Literal)
              lit_or_errors
            else
              cell_errors += lit_or_errors
              RDF::Literal(v, language: (column.lang unless column.lang == "und"))
            end
          end
        end.compact

        # Check for required values
        if column.required && (cell_values.any? {|v| v.to_s.empty?} || cell_values.empty?)
          cell_errors << "Required column has empty value(s): #{cell_values.map(&:to_s).inspect}"
        end
        cell.value = (column.separator ? cell_values : cell_values.first)
        cell.errors = cell_errors

        map_values[columns[index - skipColumns].name] = (column.separator ? cell_values.map(&:to_s) : cell_values.first.to_s)
      end

      # Record primaryKey if validating
      @primaryKey = @values.
        select {|cell| Array(table.tableSchema.primaryKey).include?(cell.column.name)} if options[:validate]

      # Record any row titles
      @titles = @values.
        select {|cell| Array(table.tableSchema.rowTitles).include?(cell.column.name)}.
        map(&:value)

      # Map URLs for row
      @values.each_with_index do |cell, index|
        mapped_values = map_values.merge(
          "_name" => CGI.unescape(cell.column.name),
          "_column" => cell.column.number,
          "_sourceColumn" => cell.column.sourceNumber
        )
        cell.set_urls(mapped_values, options[:decode_uri])
      end
    end

    # Identifier for this row, as an RFC7111 fragment 
    # @return [RDF::URI]
    def id;
      u = table.url.dup
      u.fragment = "row=#{self.sourceNumber}"
      u
    end

    # Return Annotated Row representation
    def to_atd
      {
        "@id" => id.to_s,
        "@type" => "Row",
        "table" => (table.id || table.url),
        "number" => self.number,
        "sourceNumber" => self.sourceNumber,
        "cells" => @values.map(&:value)
      }.delete_if {|k,v| v.nil?}
    end

    def inspect
      self.class.name + to_atd.inspect
    end

  private
    #
    # given a datatype specification, return a literal matching that specififcation, if found, otherwise nil
    # @return [RDF::Literal]
    def value_matching_datatype(value, datatype, expanded_dt, language)
      lit, value_errors = nil, []
      original_value = value.dup

      format = datatype.format
      # Datatype specific constraints and conversions
      case datatype.base.to_sym
      when :decimal, :integer, :long, :int, :short, :byte,
           :nonNegativeInteger, :positiveInteger,
           :unsignedLong, :unsignedInt, :unsignedShort, :unsignedByte,
           :nonPositiveInteger, :negativeInteger,
           :double, :float, :number

        # Normalize representation based on numeric-specific facets

        format = case format
        when String then {"pattern" => format}
        when Hash then format
        else {}
        end

        groupChar = format["groupChar"]
        decimalChar = format["decimalChar"] || '.'
        pattern = format["pattern"]

        begin
          value = datatype.parse_uax35_number(pattern, value, groupChar || ",", decimalChar)
        rescue UAX35::ParseError
          value_errors << "#{value} does not match numeric pattern #{pattern ? pattern.inspect : 'default'}"
        end

        lit = RDF::Literal(value, datatype: expanded_dt)

        if !lit.plain? && datatype.minimum && lit < datatype.minimum
          value_errors << "#{value} < minimum #{datatype.minimum}"
        end
        case
        when datatype.minimum && lit < datatype.minimum
          value_errors << "#{value} < minimum #{datatype.minimum}"
        when datatype.maximum && lit > datatype.maximum
          value_errors << "#{value} > maximum #{datatype.maximum}"
        when datatype.minInclusive && lit < datatype.minInclusive
          value_errors << "#{value} < minInclusive #{datatype.minInclusive}"
        when datatype.maxInclusive && lit > datatype.maxInclusive
          value_errors << "#{value} > maxInclusive #{datatype.maxInclusive}"
        when datatype.minExclusive && lit <= datatype.minExclusive
          value_errors << "#{value} <= minExclusive #{datatype.minExclusive}"
        when datatype.maxExclusive && lit >= datatype.maxExclusive
          value_errors << "#{value} ?= maxExclusive #{datatype.maxExclusive}"
        end
      when :boolean
        if format
          # True/False determined by Y|N values
          t, f = format.to_s.split('|', 2)
          case
          when value == t
            lit = RDF::Literal::TRUE
          when value == f
            lit = RDF::Literal::FALSE
          else
            value_errors << "#{value} does not match boolean format #{format}"
          end
        else
          if %w(1 true).include?(value.downcase)
            lit = RDF::Literal::TRUE
          elsif %w(0 false).include?(value.downcase)
            lit = RDF::Literal::FALSE
          else
            value_errors << "#{value} does not match boolean"
          end
        end
      when :date, :time, :dateTime, :dateTimeStamp, :datetime
        begin
          value = datatype.parse_uax35_date(format, value)
          lit = RDF::Literal(value, datatype: expanded_dt)
        rescue UAX35::ParseError
          value_errors << "#{value} does not match format #{format}"
        end
      when :duration, :dayTimeDuration, :yearMonthDuration
        # SPEC CONFUSION: surely format also includes that for other duration types?
        re = Regexp.new(format) rescue nil
        if re.nil? ||value.match(re)
          lit = RDF::Literal(value, datatype: expanded_dt)
        else
          value_errors << "#{value} does not match format #{format}"
        end
      when :hexBinary, :base64Binary
        lit = RDF::Literal.new(value, datatype: expanded_dt)
        unless lit.valid?
          value_errors << "#{value} is invalid"
          lit = RDF::Literal.new(value)
        else
          if datatype.length && lit.object.length != datatype.length
            value_errors << "decoded #{value} has length #{lit.object.length} not #{datatype.length}"
          end
          if datatype.minLength && lit.object.length < datatype.minLength
            value_errors << "decoded #{value} has length #{lit.object.length} not >= #{datatype.minLength}"
          end
          if datatype.maxLength && lit.object.length > datatype.maxLength
            value_errors << "decoded #{value} has length #{lit.object.length} not <= #{datatype.maxLength}"
          end
        end
      when :anyType, :anySimpleType, :ENTITIES, :IDREFS, :NMTOKENS,
           :ENTITY, :ID, :IDREF, :NOTATION
        value_errors << "#{value} uses unsupported datatype: #{datatype.base}"
      else
        # For other types, format is a regexp
        re = Regexp.new(format) rescue nil
        unless re.nil? || value.match(re)
          value_errors << "#{value} does not match format #{format}"
        end
        lit = if value_errors.empty?
          if expanded_dt == RDF::XSD.string
            # Type string will still use language
            RDF::Literal(value, language: (language unless language == "und"))
          else
            RDF::Literal(value, datatype: expanded_dt)
          end
        end
      end

      if datatype.length && value.to_s.length != datatype.length && ![:hexBinary, :base64Binary].include?(datatype.base.to_sym)
        value_errors << "#{value} does not have length #{datatype.length}"
      end
      if datatype.minLength && value.to_s.length < datatype.minLength && ![:hexBinary, :base64Binary].include?(datatype.base.to_sym)
        value_errors << "#{value} does not have length >= #{datatype.minLength}"
      end
      if datatype.maxLength && value.to_s.length > datatype.maxLength && ![:hexBinary, :base64Binary].include?(datatype.base.to_sym)
        value_errors << "#{value} does not have length <= #{datatype.maxLength}"
      end

      # value constraints
      value_errors << "#{value} < minimum #{datatype.minimum}"            if datatype.minimum && lit < datatype.minimum
      value_errors << "#{value} > maximum #{datatype.maximum}"            if datatype.maximum && lit > datatype.maximum
      value_errors << "#{value} < minInclusive #{datatype.minInclusive}"  if datatype.minInclusive && lit < datatype.minInclusive
      value_errors << "#{value} > maxInclusive #{datatype.maxInclusive}"  if datatype.maxInclusive && lit > datatype.maxInclusive
      value_errors << "#{value} <= minExclusive #{datatype.minExclusive}" if datatype.minExclusive && lit <= datatype.minExclusive
      value_errors << "#{value} >= maxExclusive #{datatype.maxExclusive}" if datatype.maxExclusive && lit >= datatype.maxExclusive

      # Final value is a valid literal, or a plain literal otherwise
      value_errors << "#{value} is not a valid #{datatype.base}" if lit && !lit.valid?

      # Either return matched literal value or errors
      value_errors.empty? ? lit : value_errors
    end
  end
end
