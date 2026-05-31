# -*- encoding: utf-8 -*-
# frozen_string_literal: true
require 'json/ld/format'

module YAML_LD
  ##
  # YAML-LD format specification.
  #
  # @example Obtaining an YAML-LD format class
  #     RDF::Format.for(:YAML_LD)           #=> YAML_LD::Format
  #     RDF::Format.for("etc/foaf.YAML_LD")
  #     RDF::Format.for(:file_name         => "etc/foaf.YAML_LD")
  #     RDF::Format.for(file_extension: "YAML_LD")
  #     RDF::Format.for(:content_type   => "application/ld+yaml")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"application/ld+yaml" => [YAML_LD::Format],
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {:YAML_LD => [YAML_LD::Format] }
  #
  # @see https://json-ld.github.io/yaml-ld/spec/
  # @see https://json-ld.github.io/yaml/tests/
  class Format < RDF::Format
    content_type     'application/ld+yaml',
                     extension: :yamlld,
                     uri: 'http://www.w3.org/ns/formats/YAML-LD'
    content_encoding 'utf-8'

    reader { YAML_LD::Reader }
    writer { YAML_LD::Writer }

    # Specify how to execute CLI commands for each supported format. These are added to the `LD_FORMATS` defined for `JSON::LD::Format`
    # Derived formats (e.g., YAML-LD) define their own entrypoints.
    LD_FORMATS = {
      yamlld: {
        expand: ->(input, **options) {
          YAML_LD::API.expand(input, validate: false, **options)
        },
        compact: ->(input, **options) {
          YAML_LD::API.compact(input, options[:context], **options)
        },
        flatten: ->(input, **options) {
          YAML_LD::API.flatten(input, options[:context], **options)
        },
        frame: ->(input, **options) {
          YAML_LD::API.frame(input, options[:frame], **options)
        },
      }
    }

    ##
    # Sample detection to see if it matches YAML-LD
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(/---/m)
    end

    ##
    # Override normal symbol generation
    def self.to_sym
      :yamlld
    end

    ##
    # Override normal format name
    def self.name
      "YAML-LD"
    end
  end
end


# Load into JSON::LD::Format::LD_FORMATS
::JSON::LD::Format.const_get(:LD_FORMATS).merge!(::YAML_LD::Format::LD_FORMATS)
