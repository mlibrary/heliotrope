module RDF::N3
  ##
  # RDFa format specification.
  #
  # @example Obtaining an Notation3 format class
  #     RDF::Format.for(:n3)            #=> RDF::N3::Format
  #     RDF::Format.for("etc/foaf.n3")
  #     RDF::Format.for(file_name:      "etc/foaf.n3")
  #     RDF::Format.for(file_extension: "n3")
  #     RDF::Format.for(content_type:   "text/n3")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"text/n3")" => [RDF::N3::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {n3: "text/n3"}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_type     'text/n3',             extension: :n3, aliases: %w(text/rdf+n3;q=0.2 application/rdf+n3;q=0.2)
    content_encoding 'utf-8'

    reader { RDF::N3::Reader }
    writer { RDF::N3::Writer }

    # Symbols which may be used to lookup this format
    def self.symbols
      [:n3, :notation3]
    end

    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Hash}]
    def self.cli_commands
      {
        reason: {
          description: "Reason over formulae.",
          help: "reason [--think] file\nPerform Notation-3 reasoning.",
          parse: false,
          # Only shows when input and output format set
          filter: {format: :n3},  
          repository: RDF::N3::Repository.new,
          lambda: ->(argv, **options) do
            repository = options[:repository]
            result_repo = RDF::N3::Repository.new
            RDF::CLI.parse(argv, format: :n3, list_terms: true, **options) do |reader|
              reasoner = RDF::N3::Reasoner.new(reader, **options)
              reasoner.reason!(**options)
              if options[:conclusions]
                result_repo << reasoner.conclusions
              elsif options[:data]
                result_repo << reasoner.data
              else
                result_repo << reasoner
              end
            end

            # Replace input repository with results
            repository.clear!
            repository << result_repo
          end,
          options: [
            RDF::CLI::Option.new(
              symbol: :conclusions,
              datatype: TrueClass,
              control: :checkbox,
              use: :optional,
              on: ["--conclusions"],
              description: "Exclude formulae and statements in the original dataset."),
            RDF::CLI::Option.new(
              symbol: :data,
              datatype: TrueClass,
              control: :checkbox,
              use: :optional,
              on: ["--data"],
              description: "Only results from default graph, excluding formulae or variables."),
            RDF::CLI::Option.new(
              symbol: :strings,
              datatype: TrueClass,
              control: :checkbox,
              use: :optional,
              on: ["--strings"],
              description: "Returns the concatenated strings from log:outputString."),
            RDF::CLI::Option.new(
              symbol: :think,
              datatype: TrueClass,
              control: :checkbox,
              use: :optional,
              on: ["--think"],
              description: "Continuously execute until results stop growing."),
          ]
        },
      }
    end
  end
end
