module LD::Patch
  ##
  # LD::Patch format specification. Note that this format does not define any readers or writers.
  #
  # @example Obtaining an LD Patch format class
  #     RDF::Format.for(:ldp)           #=> LD::Patch::Format
  #     RDF::Format.for("etc/foaf.ldp")
  #     RDF::Format.for(:file_name         => "etc/foaf.ldp")
  #     RDF::Format.for(file_extension: "ldp")
  #     RDF::Format.for(:content_type   => "text/ldpatch")
  #
  # @see http://www.w3.org/TR/ldpatch/
  class Format < RDF::Format
    content_type     'text/ldpatch',
                     extension: :ldp,
                     uri: 'http://www.w3.org/ns/formats/LD_Patch'
    content_encoding 'utf-8'

    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Lambda(Array, Hash)}]
    def self.cli_commands
      {
        patch: {
          description: "Patch the current graph using a patch file",
          help: "patch [--patch-input 'patch'] [--patch-file file]",
          control: :button,
          parse: true,
          lambda: -> (argv, opts) do
            opts[:patch_input] ||= case opts[:patch_file]
            when IO, StringIO then opts[:patch_file]
            else RDF::Util::File.open_file(opts[:patch_file]) {|f| f.read}
            end
            raise ArgumentError, "Patching requires a patch or reference to patch resource" unless opts[:patch_input]
            opts[:logger].info "Patch"
            patch = LD::Patch.parse(opts[:patch_input], base_uri: opts.fetch(:patch_file, "https://rubygems.org/gems/ld-patch"))
            opts[:messages][:reasoner] = {"S-Expression": [patch.to_sse]} if opts[:to_sxp]
            RDF::CLI.repository.query(patch)
          end,
          options: [
            RDF::CLI::Option.new(
              symbol: :patch_input,
              datatype: String,
              control: :none,
              on: ["--patch-input STRING"],
              description: "Patch in URI encoded format"
            ) {|v| CGI.decode(v)},
            RDF::CLI::Option.new(
              symbol: :patch_file,
              datatype: String,
              control: :url2,
              on: ["--patch-file URI"],
              description: "Patch file"
            ) {|v| RDF::URI(v)},
            RDF::CLI::Option.new(
              symbol: :to_sxp,
              datatype: String,
              control: :checkbox,
              on: ["--to-sxp"],
              description: "Instead of patching repository, display parsed patch as an S-Expression"
            ),
          ]
        }
      }
    end

    def self.to_sym; :ldpatch; end
  end
end
