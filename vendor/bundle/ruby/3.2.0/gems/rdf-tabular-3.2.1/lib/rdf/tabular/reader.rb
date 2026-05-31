require 'rdf'
require 'rdf/vocab'

module RDF::Tabular
  ##
  # A Tabular Data to RDF parser in Ruby.
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Reader < RDF::Reader
    format Format
    include RDF::Util::Logger

    # Metadata associated with the CSV
    #
    # @return [Metadata]
    attr_reader :metadata

    ##
    # Input open to read
    # @return [:read]
    attr_reader :input

    ##
    # Writer options
    # @see https://ruby-rdf.github.io/rdf/RDF/Writer#options-class_method
    def self.options
      super + [
        RDF::CLI::Option.new(
          symbol: :metadata,
          datatype: RDF::URI,
          control: :url2,
          on: ["--metadata URI"],
          description: "user supplied metadata, merged on top of extracted metadata. If provided as a URL, Metadata is loade from that location.") {|arg| RDF::URI(arg)},
        RDF::CLI::Option.new(
          symbol: :minimal,
          control: :checkbox,
          datatype: TrueClass,
          on: ["--minimal"],
          description: "Includes only the information gleaned from the cells of the tabular data.") {true},
        RDF::CLI::Option.new(
          symbol: :noProv,
          datatype: TrueClass,
          control: :checkbox,
          on: ["--no-prov"],
          description: "do not output optional provenance information.") {true},
        RDF::CLI::Option.new(
          symbol: :decode_uri,
          datatype: TrueClass,
          control: :checkbox,
          on: ["--decode-uri"],
          description: "decode %-encodings in the result of a URI Template operation."
        )
      ]
    end

    ##
    # Initializes the RDF::Tabular Reader instance.
    #
    # @param  [Util::File::RemoteDoc, IO, StringIO, Array<Array<String>>, String]       input
    #   An opened file possibly JSON Metadata,
    #   or an Array used as an internalized array of arrays
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize`)
    # @option options [Boolean] :decode_uri
    #   Decode %-encodings in the result of a URI Template operation.
    # @option options [Array<Hash>] :fks_referencing_table
    #   When called with Table metadata, a list of the foreign keys referencing this table
    # @option options [Metadata, Hash, String, RDF::URI] :metadata user supplied metadata, merged on top of extracted metadata. If provided as a URL, Metadata is loade from that location
    # @option options [Boolean] :minimal includes only the information gleaned from the cells of the tabular data
    # @option options [Boolean] :noProv do not output optional provenance information
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [RDF::ReaderError] if the CSV document cannot be loaded
    def initialize(input = $stdin, **options, &block)
      super do
        # Base would be how we are to take this
        @options[:base] ||= base_uri.to_s if base_uri
        @options[:base] ||= input.base_uri if input.respond_to?(:base_uri)
        @options[:base] ||= input.path if input.respond_to?(:path)
        @options[:base] ||= input.filename if input.respond_to?(:filename)
        if RDF::URI(@options[:base]).relative? && File.exist?(@options[:base].to_s)
          file_uri = "file:" + File.expand_path(@options[:base])
          @options[:base] = RDF::URI(file_uri.to_s).normalize
        end

        log_debug("Reader#initialize") {"input: #{input.inspect}, base: #{@options[:base]}"}

        # Minimal implies noProv
        @options[:noProv] ||= @options[:minimal]

        @input = case input
        when String then StringIO.new(input)
        when Array then StringIO.new(input.map {|r| r.join(",")}.join("\n"))
        else input
        end

        log_depth do
          # If input is JSON, then the input is the metadata
          content_type = @input.respond_to?(:content_type) ? @input.content_type : ""
          if @options[:base] =~ /\.json(?:ld)?$/ || content_type =~ %r(application/(csvm\+|ld\+)?json)
            @metadata = Metadata.new(@input, filenames: @options[:base], **@options)
            # If @metadata is for a Table, turn it into a TableGroup
            @metadata = @metadata.to_table_group if @metadata.is_a?(Table)
            @metadata.normalize!
            @input = @metadata
          elsif (@options[:base].to_s.end_with?(".html") || %w(text/html application/xhtml+html).include?(content_type)) &&
                !RDF::URI(@options[:base].to_s).fragment
            require 'nokogiri' unless defined?(:Nokogiri)
            doc = Nokogiri::HTML.parse(input)
            doc.xpath("//script[@type='application/csvm+json']/text()").each do |script|
              def script.content_type; "application/csvm+json"; end
              log_debug("Reader#initialize") {"Process HTML script block"}
              @input = script
              @metadata = Metadata.new(@input, filenames: @options[:base], **@options)
              # If @metadata is for a Table, turn it into a TableGroup
              @metadata = @metadata.to_table_group if @metadata.is_a?(Table)
              @metadata.normalize!
              @input = @metadata
            end
          elsif @options[:no_found_metadata]
            # Extract embedded metadata and merge
            dialect_metadata = @options[:metadata] || Table.new({}, context: "http://www.w3.org/ns/csvw")
            dialect = dialect_metadata.dialect.dup

            # HTTP flags for setting header values
            dialect.header = false if (input.headers.fetch(:content_type, '').split(';').include?('header=absent') rescue false)
            dialect.encoding = input.charset if (input.charset rescue nil)
            dialect.separator = "\t" if (input.content_type == "text/tsv" rescue nil)
            embed_options = @options.dup
            embed_options[:lang] = dialect_metadata.lang if dialect_metadata.lang
            embedded_metadata = dialect.embedded_metadata(input, @options[:metadata], **embed_options)

            if (@metadata = @options[:metadata]) && @metadata.tableSchema
              @metadata.verify_compatible!(embedded_metadata)
            else
              @metadata = embedded_metadata.normalize!
            end

            lang = input.headers[:content_language] rescue nil
            lang = nil if lang.to_s.include?(',') # Not for multiple languages
            # Set language, if unset and provided
            @metadata.lang ||= lang if lang 
              
            @metadata.dialect = dialect
          else
            # It's tabluar data. Find metadata and proceed as if it was specified in the first place
            @options[:original_input] = @input unless @options[:metadata]
            @input = @metadata = Metadata.for_input(@input, **@options).normalize!
          end

          log_debug("Reader#initialize") {"input: #{input}, metadata: #{metadata.inspect}"}

          if block_given?
            case block.arity
              when 0 then instance_eval(&block)
              else block.call(self)
            end
          end
        end
      end
    end

    ##
    # @private
    # @see   RDF::Reader#each_statement
    def each_statement(&block)
      if block_given?
        @callback = block

        start_time = Time.now

        # Construct metadata from that passed from file open, along with information from the file.
        if input.is_a?(Metadata)
          log_debug("each_statement: metadata") {input.inspect}

          log_depth do
            begin
              # Validate metadata
              input.validate!

              # Use resolved @id of TableGroup, if available
              table_group = input.id || RDF::Node.new
              add_statement(0, table_group, RDF.type, CSVW.TableGroup) unless minimal?

              # Common Properties
              input.each do |key, value|
                next unless key.to_s.include?(':') || key == :notes
                input.common_properties(table_group, key, value) do |statement|
                  add_statement(0, statement)
                end
              end unless minimal?

              # If we were originally given tabular data as input, simply use that, rather than opening the table URL. This allows buffered data to be used as input.
              # This case also handles found metadata that doesn't describe the input file
              if options[:original_input] && !input.describes_file?(options[:base_uri])
                table_resource = RDF::Node.new
                add_statement(0, table_group, CSVW.table, table_resource) unless minimal?
                Reader.new(options[:original_input], **options.merge(
                    metadata: input.tables.first,
                    base: input.tables.first.url,
                    no_found_metadata: true,
                    table_resource: table_resource,
                )) do |r|
                  r.each_statement(&block)
                end
              else
                input.each_table do |table|
                  # If validating, continue on to process value restrictions
                  next if table.suppressOutput && !validate?

                  # Foreign Keys referencing this table
                  fks = input.tables.map do |t|
                    t.tableSchema && t.tableSchema.foreign_keys_referencing(table)
                  end.flatten.compact
                  table_resource = table.id || RDF::Node.new
                  add_statement(0, table_group, CSVW.table, table_resource) unless minimal?
                  Reader.open(table.url, **options.merge(
                      metadata: table,
                      base: table.url,
                      no_found_metadata: true,
                      table_resource: table_resource,
                      fks_referencing_table: fks,
                  )) do |r|
                    r.each_statement(&block)
                  end
                end

                # Lastly, if validating, validate foreign key integrity
                validate_foreign_keys(input) if validate?
              end

              # Provenance
              if prov?
                activity = RDF::Node.new
                add_statement(0, table_group, RDF::Vocab::PROV.wasGeneratedBy, activity)
                add_statement(0, activity, RDF.type, RDF::Vocab::PROV.Activity)
                add_statement(0, activity, RDF::Vocab::PROV.wasAssociatedWith, RDF::URI("https://rubygems.org/gems/rdf-tabular"))
                add_statement(0, activity, RDF::Vocab::PROV.startedAtTime, RDF::Literal::DateTime.new(start_time))
                add_statement(0, activity, RDF::Vocab::PROV.endedAtTime, RDF::Literal::DateTime.new(Time.now))

                unless (urls = input.tables.map(&:url)).empty?
                  usage = RDF::Node.new
                  add_statement(0, activity, RDF::Vocab::PROV.qualifiedUsage, usage)
                  add_statement(0, usage, RDF.type, RDF::Vocab::PROV.Usage)
                  urls.each do |url|
                    add_statement(0, usage, RDF::Vocab::PROV.entity, RDF::URI(url))
                  end
                  add_statement(0, usage, RDF::Vocab::PROV.hadRole, CSVW.csvEncodedTabularData)
                end

                unless Array(input.filenames).empty?
                  usage = RDF::Node.new
                  add_statement(0, activity, RDF::Vocab::PROV.qualifiedUsage, usage)
                  add_statement(0, usage, RDF.type, RDF::Vocab::PROV.Usage)
                  Array(input.filenames).each do |fn|
                    add_statement(0, usage, RDF::Vocab::PROV.entity, RDF::URI(fn))
                  end
                  add_statement(0, usage, RDF::Vocab::PROV.hadRole, CSVW.tabularMetadata)
                end
              end
            end
          end

          if validate? && log_statistics[:error]
            raise RDF::ReaderError, "Errors found during processing"
          end
          return
        end

        # Output Table-Level RDF triples
        table_resource = options.fetch(:table_resource, (metadata.id || RDF::Node.new))
        unless minimal? || metadata.suppressOutput
          add_statement(0, table_resource, RDF.type, CSVW.Table)
          add_statement(0, table_resource, CSVW.url, RDF::URI(metadata.url))
        end

        # Input is file containing CSV data.
        # Output ROW-Level statements
        last_row_num = 0
        primary_keys = []
        metadata.each_row(input) do |row|
          if row.is_a?(RDF::Statement)
            # May add additional comments
            row.subject = table_resource
            add_statement(last_row_num + 1, row) unless metadata.suppressOutput
            next
          else
            last_row_num = row.sourceNumber
          end

          # Collect primary and foreign keys if validating
          if validate?
            primary_keys << row.primaryKey
            collect_foreign_key_references(metadata, options[:fks_referencing_table], row)
          end

          next if metadata.suppressOutput

          # Output row-level metadata
          row_resource = RDF::Node.new
          default_cell_subject = RDF::Node.new
          unless minimal?
            add_statement(row.sourceNumber, table_resource, CSVW.row, row_resource)
            add_statement(row.sourceNumber, row_resource, CSVW.rownum, row.number)
            add_statement(row.sourceNumber, row_resource, RDF.type, CSVW.Row)
            add_statement(row.sourceNumber, row_resource, CSVW.url, row.id)
            row.titles.each do |t|
              add_statement(row.sourceNumber, row_resource, CSVW.title, t)
            end
          end
          row.values.each_with_index do |cell, index|
            # Collect cell errors
            unless Array(cell.errors).empty?
              self.send((validate? ? :log_error : :log_warn),
                       "Table #{metadata.url} row #{row.number}(src #{row.sourceNumber}, col #{cell.column.sourceNumber})") do
                cell.errors.join("\n")
              end
            end
            next if cell.column.suppressOutput # Skip ignored cells
            cell_subject = cell.aboutUrl || default_cell_subject
            propertyUrl = cell.propertyUrl || begin
              # It's possible that the metadata URL already has a fragment, in which case we need to override it.
              u = metadata.url.dup
              u.fragment = cell.column.name
              u
            end
            add_statement(row.sourceNumber, row_resource, CSVW.describes, cell_subject) unless minimal?

            if cell.column.valueUrl
              add_statement(row.sourceNumber, cell_subject, propertyUrl, cell.valueUrl) if cell.valueUrl
            elsif cell.column.ordered && cell.column.separator
              list = RDF::List[*Array(cell.value)]
              add_statement(row.sourceNumber, cell_subject, propertyUrl, list.subject)
              list.each_statement do |statement|
                next if statement.predicate == RDF.type && statement.object == RDF.List
                add_statement(row.sourceNumber, statement.subject, statement.predicate, statement.object)
              end
            else
              Array(cell.value).each do |v|
                add_statement(row.sourceNumber, cell_subject, propertyUrl, v)
              end
            end
          end
        end

        # Validate primary keys
        validate_primary_keys(metadata, primary_keys) if validate?

        # Common Properties
        metadata.each do |key, value|
          next unless key.to_s.include?(':') || key == :notes
          metadata.common_properties(table_resource, key, value) do |statement|
            add_statement(0, statement)
          end
        end unless minimal?
      end
      enum_for(:each_statement)
    rescue IOError => e
      raise RDF::ReaderError, e.message, e.backtrace
    end

    ##
    # @private
    # @see   RDF::Reader#each_triple
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end

    ##
    # Do we have valid metadata?
    # @raise [RDF::ReaderError]
    def validate!
      @options[:validate] = true
      each_statement {}
    rescue RDF::ReaderError => e
      raise Error, e.message
    end

    ##
    # Transform to JSON. Note that this must be run from within the reader context if the input is an open IO stream.
    #
    # @example outputing annotated CSV as JSON
    #     result = nil
    #     RDF::Tabular::Reader.open("etc/doap.csv") do |reader|
    #       result = reader.to_json
    #     end
    #     result #=> {...}
    #
    # @example outputing annotated CSV as JSON from an in-memory structure
    #     csv = %(
    #       GID,On Street,Species,Trim Cycle,Inventory Date
    #       1,ADDISON AV,Celtis australis,Large Tree Routine Prune,10/18/2010
    #       2,EMERSON ST,Liquidambar styraciflua,Large Tree Routine Prune,6/2/2010
    #       3,EMERSON ST,Liquidambar styraciflua,Large Tree Routine Prune,6/2/2010
    #     ).gsub(/^\s+/, '')
    #     r = RDF::Tabular::Reader.new(csv)
    #     r.to_json #=> {...}
    #
    # @param [Hash{Symbol => Object}] options may also be a JSON state
    # @option options [IO, StringIO] io to output to file
    # @option options [::JSON::State] :state used when dumping
    # @option options [Boolean] :atd output Abstract Table representation instead
    # @return [String]
    # @raise [RDF::Tabular::Error]
    def to_json(options = @options)
      io = case options
      when IO, StringIO then options
      when Hash then options[:io]
      end
      json_state = case options
      when Hash
        case
        when options.has_key?(:state) then options[:state]
        when options.has_key?(:indent) then options
        else ::JSON::LD::JSON_STATE
        end
      when ::JSON::State, ::JSON::Ext::Generator::State, ::JSON::Pure::Generator::State
        options
      else ::JSON::LD::JSON_STATE
      end
      options = {} unless options.is_a?(Hash)

      hash_fn = :to_hash
      options = options.merge(noProv: @options[:noProv])

      res = if io
        ::JSON::dump_default_options = json_state
        ::JSON.dump(self.send(hash_fn, **options), io)
      else
        hash = self.send(hash_fn, **options)
        ::JSON.generate(hash, json_state)
      end

      if validate? && log_statistics[:error]
        raise RDF::Tabular::Error, "Errors found during processing"
      end

      res
    rescue IOError => e
      raise RDF::Tabular::Error, e.message
    end

    ##
    # Return a hash representation of the data for JSON serialization
    #
    # Produces an array if run in minimal mode.
    #
    # @param [Hash{Symbol => Object}] options
    # @return [Hash, Array]
    def to_hash(**options)
      # Construct metadata from that passed from file open, along with information from the file.
      if input.is_a?(Metadata)
        log_debug("each_statement: metadata") {input.inspect}
        log_depth do
          # Get Metadata to invoke and open referenced files
          begin
            # Validate metadata
            input.validate!

            tables = []
            table_group = {}
            table_group['@id'] = input.id.to_s if input.id

            # Common Properties
            input.each do |key, value|
              next unless key.to_s.include?(':') || key == :notes
              table_group[key] = input.common_properties(nil, key, value)
              table_group[key] = [table_group[key]] if key == :notes && !table_group[key].is_a?(Array)
            end

            table_group['tables'] = tables

            if options[:original_input] && !input.describes_file?(options[:base_uri])
              Reader.new(options[:original_input], **options.merge(
                  metadata:           input.tables.first,
                  base:               input.tables.first.url,
                  minimal:            minimal?,
                  no_found_metadata:  true,
              )) do |r|
                case t = r.to_hash(**options)
                when Array then tables += t unless input.tables.first.suppressOutput
                when Hash  then tables << t unless input.tables.first.suppressOutput
                end
              end
            else
              input.each_table do |table|
                next if table.suppressOutput && !validate?
                Reader.open(table.url, **options.merge(
                  metadata:           table,
                  base:               table.url,
                  minimal:            minimal?,
                  no_found_metadata:  true,
                )) do |r|
                  case t = r.to_hash(**options)
                  when Array then tables += t unless table.suppressOutput
                  when Hash  then tables << t unless table.suppressOutput
                  end
                end
              end
            end

            # Lastly, if validating, validate foreign key integrity
            validate_foreign_keys(input) if validate?

            # Result is table_group or array
            minimal? ? tables : table_group
          end
        end
      else
        rows = []
        table = {}
        table['@id'] = metadata.id.to_s if metadata.id
        table['url'] = metadata.url.to_s

        table.merge!("row" => rows)

        # Input is file containing CSV data.
        # Output ROW-Level statements
        primary_keys = []
        metadata.each_row(input) do |row|
          if row.is_a?(RDF::Statement)
            # May add additional comments
            table['rdfs:comment'] ||= []
            table['rdfs:comment'] << row.object.to_s
            next
          end

          # Collect primary and foreign keys if validating
          if validate?
            primary_keys << row.primaryKey
            collect_foreign_key_references(metadata, options[:fks_referencing_table], row)
          end

          # Output row-level metadata
          r, a, values = {}, {}, {}
          r["url"] = row.id.to_s
          r["rownum"] = row.number

          # Row titles
          Array(row.titles).each { |t| merge_compacted_value(r, "titles", t.to_s) unless t.nil?}

          row.values.each_with_index do |cell, index|
            column = metadata.tableSchema.columns[index]

            # Collect cell errors
            unless Array(cell.errors).empty?
              self.send(validate? ? :log_error : :log_warn,
                "Table #{metadata.url} row #{row.number}(src #{row.sourceNumber}, col #{cell.column.sourceNumber}): ") do
                cell.errors.join("\n")
              end
            end

            # Ignore suppressed columns
            next if column.suppressOutput

            # Skip valueUrl cells where the valueUrl is null
            next if cell.column.valueUrl && cell.valueUrl.nil?

            # Skip empty sequences
            next if !cell.column.valueUrl && cell.value.is_a?(Array) && cell.value.empty?

            subject = cell.aboutUrl || 'null'
            co = (a[subject.to_s] ||= {})
            co['@id'] = subject.to_s unless subject == 'null'
            prop = case cell.propertyUrl
            when RDF.type then '@type'
            when nil then CGI.unescape(column.name) # Use URI-decoded name
            else
              # Compact the property to a term or prefixed name
              metadata.context.compact_iri(cell.propertyUrl, vocab: true)
            end

            value = case
            when prop == '@type'
              metadata.context.compact_iri(cell.valueUrl || cell.value, vocab: true)
            when cell.valueUrl
              unless subject == cell.valueUrl
                values[cell.valueUrl.to_s] ||= {o: co, prop: prop, count: 0}
                values[cell.valueUrl.to_s][:count] += 1
              end
              cell.valueUrl.to_s
            when cell.value.is_a?(RDF::Literal::Double)
              cell.value.object.nan? || cell.value.object.infinite? ? cell.value : cell.value.object
            when cell.value.is_a?(RDF::Literal::Integer)
              cell.value.object.to_i
            when cell.value.is_a?(RDF::Literal::Numeric)
              cell.value.object.to_f
            when cell.value.is_a?(RDF::Literal::Boolean)
              cell.value.object
            when cell.value
              cell.value
            end

            # Add or merge value
            merge_compacted_value(co, prop, value) unless value.nil?
          end

          # Check for nesting
          values.keys.each do |valueUrl|
            next unless a.has_key?(valueUrl)
            ref = values[valueUrl]
            co = ref[:o]
            prop = ref[:prop]
            next if ref[:count] != 1
            raise "Expected #{ref[o][prop].inspect} to include #{valueUrl.inspect}" unless Array(co[prop]).include?(valueUrl)
            co[prop] = Array(co[prop]).map {|e| e == valueUrl ? a.delete(valueUrl) : e}
            co[prop] = co[prop].first if co[prop].length == 1
          end

          r["describes"] = a.values

          if minimal?
            rows.concat(r["describes"])
          else
            rows << r
          end
        end

        # Validate primary keys
        validate_primary_keys(metadata, primary_keys) if validate?

        # Use string values notes and common properties
        metadata.each do |key, value|
          next unless key.to_s.include?(':') || key == :notes
          table[key] = metadata.common_properties(nil, key, value)
          table[key] = [table[key]] if key == :notes && !table[key].is_a?(Array)
        end unless minimal?

        minimal? ? table["row"] : table
      end
    end

    def minimal?; @options[:minimal]; end
    def prov?; !(@options[:noProv]); end

    private
    ##
    # @overload add_statement(lineno, statement)
    #   Add a statement, object can be literal or URI or bnode
    #   @param [String] lineno
    #   @param [RDF::Statement] statement
    #   @yield [RDF::Statement]
    #   @raise [ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    #
    # @overload add_statement(lineno, subject, predicate, object)
    #   Add a triple
    #   @param [URI, BNode] subject the subject of the statement
    #   @param [URI] predicate the predicate of the statement
    #   @param [URI, BNode, Literal] object the object of the statement
    #   @raise [ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(node, *args)
      statement = args[0].is_a?(RDF::Statement) ? args[0] : RDF::Statement(*args)
      raise RDF::ReaderError, "#{statement.inspect} is invalid" if validate? && statement.invalid?
      log_debug(node) {"statement: #{RDF::NTriples.serialize(statement)}".chomp}
      @callback.call(statement)
    end

    # Validate primary keys
    def validate_primary_keys(metadata, primary_keys)
      pk_strings = {}
      primary_keys.reject(&:empty?).each do |row_pks|
        pk_names = row_pks.map {|cell| cell.value}.join(",")
        log_error "Table #{metadata.url} has duplicate primary key #{pk_names}" if pk_strings.has_key?(pk_names)
        pk_strings[pk_names] ||= 0
        pk_strings[pk_names] += 1
      end
    end

    # Collect foreign key references
    # @param [Table] metadata
    # @param [Array<Hash>] foreign_keys referencing this table
    # @param [Row] row
    def collect_foreign_key_references(metadata, foreign_keys, row)
      schema = metadata.tableSchema

      # Add row as foreignKey source
      Array(schema ? schema.foreignKeys : []).each do |fk|
        colRef = Array(fk['columnReference'])

        # Referenced cells, in order
        cells = colRef.map {|n| row.values.detect {|cell| cell.column.name == n}}.compact
        cell_values = cells.map {|cell| cell.stringValue unless cell.stringValue.to_s.empty?}.compact
        next if cell_values.empty?  # Don't record if empty
        (fk[:reference_from] ||= {})[cell_values] ||= row
      end

      # Add row as foreignKey dest
      Array(foreign_keys).each do |fk|
        colRef = Array(fk['reference']['columnReference'])

        # Referenced cells, in order
        cells = colRef.map {|n| row.values.detect {|cell| cell.column.name == n}}.compact
        fk[:reference_to] ||= {}
        cell_values = cells.map {|cell| cell.stringValue unless cell.stringValue.to_s.empty?}.compact
        next if cell_values.empty?  # Don't record if empty
        log_error "Table #{metadata.url} row #{row.number}(src #{row.sourceNumber}): found duplicate foreign key target: #{cell_values.map(&:to_s).inspect}" if fk[:reference_to][cell_values]
        fk[:reference_to][cell_values] ||= row
      end
    end

    # Validate foreign keys
    def validate_foreign_keys(metadata)
      metadata.tables.each do |table|
        next if (schema = table.tableSchema).nil?
        schema.foreignKeys.each do |fk|
          # Verify that reference_from entry exists in reference_to
          fk.fetch(:reference_from, {}).each do |cell_values, row|
            unless fk.fetch(:reference_to, {}).has_key?(cell_values)
              log_error "Table #{table.url} row #{row.number}(src #{row.sourceNumber}): " +
                        "Foreign Key violation, expected to find #{cell_values.map(&:to_s).inspect}"
            end
          end
        end if schema.foreignKeys
      end
    end

    # Merge values into compacted results, creating arrays if necessary
    def merge_compacted_value(hash, key, value)
      return unless hash
      case hash[key]
      when nil then hash[key] = value
      when Array
        if value.is_a?(Array)
          hash[key].concat(value)
        else
          hash[key] << value
        end
      else
        hash[key] = [hash[key]]
        if value.is_a?(Array)
          hash[key].concat(value)
        else
          hash[key] << value
        end
      end
    end
  end
end

