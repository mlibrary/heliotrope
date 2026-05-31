require 'rdf/format'

module SHACL
  ##
  # SHACL format specification. Note that this format does not define any readers or writers.
  #
  # @example Obtaining an ShEx format class
  #     RDF::Format.for(:shacl)           #=> ShEx::Format
  class Format < RDF::Format
    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Lambda(Array, Hash)}]
    def self.cli_commands
      {
        shacl: {
          description: "Validate repository given shape",
          help: %(shacl [--shape URI] [--focus Resource] [--replace]

            Evaluates the repository according the the specified shapes.
            If no shape file is specified, it will look for one or more
            shapes graphs using the sh:shapesGraph property found within
            the repository.
            ).gsub(/^\s+/, ''),
          parse: true,
          lambda: -> (argv, **options) do
            shacl = case options[:shape]
            when IO, StringIO
              SHACL.get_shapes(RDF::Reader.new(options[:shape]), **options)
            when nil
              SHACL.from_queryable(RDF::CLI.repository, **options)
            else SHACL.open(options[:shape], **options)
            end

            if options[:to_sxp]
              options[:messages][:shacl] = {}
              options[:messages][:shacl].merge!({"S-Expression": [SXP::Generator.string(shacl.to_sxp_bin)]})
            else
              start = Time.now
              report = shacl.execute(RDF::CLI.repository, **options)
              secs = Time.new - start
              options[:logger].info "SHACL resulted in #{report.conform? ? 'success' : 'failure'} including #{report.count} results."
              options[:logger].info "Validated in #{secs} seconds."
              options[:messages][:shacl] = {result: report.conform? ? "Satisfied shape" : "Did not satisfy shape"}
              if report.conform?
                options[:messages][:shacl] = {result: ["Satisfied shape"]}
              else
                RDF::CLI.repository << report
                options[:messages][:shacl] = {result: ["Did not satisfy shape: #{report.count} results"]}
                options[:messages].merge!(report.linter_messages)
              end
            end
            RDF::CLI.repository
          end,
          options: [
            RDF::CLI::Option.new(
              symbol: :focus,
              datatype: String,
              control: :text,
              on: ["--focus Resource"],
              description: "Focus node within repository"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :replace,
              datatype: TrueClass,
              control: :checkbox,
              on: ["--replace"],
              description: "Replaces the data graph with the validation report"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :shape,
              datatype: String,
              control: :url2,
              on: ["--shape URI"],
              description: "SHACL shapes graph location"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :to_sxp,
              datatype: String,
              control: :checkbox,
              on: ["--to-sxp"],
              description: "Display parsed shapes as an S-Expression"
            ),
          ]
        }
      }
    end
  end
end
