require 'rdf/format'

module ShEx
  ##
  # ShEx format specification. Note that this format does not define any readers or writers.
  #
  # @example Obtaining an ShEx format class
  #     RDF::Format.for(:shex)           #=> ShEx::Format
  #     RDF::Format.for("etc/foaf.shex")
  #     RDF::Format.for(file_name:      "etc/foaf.shex")
  #     RDF::Format.for(file_extension: "shex")
  #     RDF::Format.for(content_type:   "application/shex")
  class Format < RDF::Format
    content_type     'application/shex', extension: :shex
    content_encoding 'utf-8'

    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Lambda(Array, Hash)}]
    def self.cli_commands
      {
        shex: {
          description: "Validate repository given shape",
          help: "shex [--shape Resource] [--focus Resource] [--schema-input STRING] [--schema STRING] file",
          parse: true,
          lambda: -> (argv, **options) do
            options[:schema_input] ||= case options[:schema]
            when IO, StringIO then options[:schema]
            else RDF::Util::File.open_file(options[:schema]) {|f| f.read}
            end
            raise ArgumentError, "Shape matching requires a schema or reference to schema resource" unless options[:schema_input]
            raise ArgumentError, "Shape matching requires a focus node" unless options[:focus]
            format = options[:schema].to_s.end_with?('json') ? 'shexj' : 'shexc'
            shex = ShEx.parse(options[:schema_input], format: format, **options)

            if options[:to_sxp] || options[:to_json]
              options[:messages][:shex] = {}
              options[:messages][:shex].merge!({"S-Expression": [SXP::Generator.string(shex.to_sxp_bin)]}) if options[:to_sxp]
              options[:messages][:shex].merge!({ShExJ: [shex.to_json(JSON::LD::JSON_STATE)]}) if options[:to_json]
            else
              focus = options.delete(:focus)
              shape = options.delete(:shape)
              map = shape ? {focus => shape} : {}
              begin
                res = shex.execute(RDF::CLI.repository, map, focus: focus, **options)
                options[:messages][:shex] = {
                  result: ["Satisfied shape."],
                  detail: [SXP::Generator.string(res.to_sxp_bin)]
                }
              rescue ShEx::NotSatisfied => e
                options[:logger].error e.to_s
                options[:messages][:shex] = {
                  result: ["Did not satisfied shape."],
                  detail: [SXP::Generator.stringe.expression]
                }
                raise
              end
            end
          end,
          options: [
            RDF::CLI::Option.new(
              symbol: :focus,
              datatype: String,
              control: :text,
              use: :required,
              on: ["--focus Resource"],
              description: "Focus node within repository"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :shape,
              datatype: String,
              control: :text,
              use: :optional,
              on: ["--shape URI"],
              description: "Shape identifier within ShEx schema"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :schema_input,
              datatype: String,
              control: :none,
              on: ["--schema-input STRING"],
              description: "ShEx schema in URI encoded format"
            ) {|v| URI.decode(v)},
            RDF::CLI::Option.new(
              symbol: :schema,
              datatype: String,
              control: :url2,
              on: ["--schema URI"],
              description: "ShEx schema location"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :to_json,
              datatype: String,
              control: :checkbox,
              on: ["--to-json"],
              description: "Display parsed schema as ShExJ"
            ),
            RDF::CLI::Option.new(
              symbol: :to_sxp,
              datatype: String,
              control: :checkbox,
              on: ["--to-sxp"],
              description: "Display parsed schema as an S-Expression"
            ),
          ]
        }
      }
    end
  end
end
