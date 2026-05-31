module RDF::Reasoner
  ##
  # LD::Patch format specification. Note that this format does not define any readers or writers.
  #
  # @example Obtaining an LD Patch format class
  #     RDF::Format.for(:reasoner)           #=> RDF::Reasoner::Format
  #
  # @see https://www.w3.org/TR/ldpatch/
  class Format < RDF::Format

    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Lambda(Array, Hash)}]
    def self.cli_commands
      {
        entail: {
          description: "Add entailed triples to repository",
          help: "entail\nPerform RDFS, OWL and schema.org entailment to expand the repository based on referenced built-in vocabuaries",
          control: :button, # Treats this like a separate control in the HTML UI
          parse: true,
          lambda: ->(argv, opts) do
            RDF::Reasoner.apply(:rdfs, :owl, :schema)
            start, stmt_cnt = Time.now, RDF::CLI.repository.count
            RDF::CLI.repository.entail!
            secs, new_cnt = (Time.new - start), (RDF::CLI.repository.count - stmt_cnt)
            opts[:logger].info "Entailed #{new_cnt} new statements in #{secs} seconds."
          end
        },
        lint: {
          description: "Lint the repository",
          help: "lint\nLint the repository using built-in vocabularies",
          parse: true,
          option_use: {output_format: :disabled},
          lambda: ->(argv, opts) do
            RDF::Reasoner.apply(:rdfs, :owl, :schema)
            start = Time.now
            # Messages added to opts for appropriate display
            opts[:messages].merge!(RDF::CLI.repository.lint)
            opts[:output].puts "Linter responded with #{opts[:messages].empty? ? 'no' : ''} messages."
            secs = Time.new - start
            opts[:logger].info "Linted in #{secs} seconds."
          end
        }
      }
    end
  end
end
