# Attempt to load RDF::RDFa first, so that RDF::Format.for(:rdfa) is defined
begin
  require 'rdf/rdfa'
rescue LoadError
  # Soft error
end

module RDF::Microdata
  ##
  # Microdata format specification.
  #
  # @example Obtaining a Microdata format class
  #   RDF::Format.for(:microdata)         #=> RDF::Microdata::Format
  #   RDF::Format.for("etc/foaf.html")
  #   RDF::Format.for(:file_name      => "etc/foaf.html")
  #   RDF::Format.for(file_extension: "html")
  #   RDF::Format.for(:content_type   => "text/html")
  #
  # @example Obtaining serialization format MIME types
  #   RDF::Format.content_types      #=> {"text/html" => [RDF::Microdata::Format]}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_encoding 'utf-8'

    # Only define content type if RDFa is not available.
    # The Microdata processor will be launched from there
    # otherwise.
    content_type     'text/html;q=0.5', extension: :html unless RDF::Format.for(:rdfa)
    reader { RDF::Microdata::Reader }
  
    ##
    # Sample detection to see if it matches Microdata (not RDF/XML or RDFa)
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement
    # a matcher sufficient to detect probably format matches, including disambiguating
    # between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(/<[^>]*(itemprop|itemtype|itemref|itemscope|itemid)[^>]*>/m)
    end

    ##
    # Hash of CLI commands appropriate for this format
    # @return [Hash{Symbol => Hash}]
    def self.cli_commands
      {
        "to-rdfa": {
          description: "Transform HTML+Microdata into HTML+RDFa",
          parse: false,
          help: "to-rdfa files ...\nTransform HTML+Microdata into HTML+RDFa",
          filter: {
            format: :microdata
          },
          option_use: {output_format: :disabled},
          lambda: ->(files, **options) do
            out = options[:output] || $stdout
            xsl = Nokogiri::XSLT(%(<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              <xsl:param name="indent-increment" select="'  '"/>
              <xsl:output method="html" doctype-system="about:legacy-compat"/>
 
              <xsl:template name="newline">
                <xsl:text disable-output-escaping="yes">
            </xsl:text>
              </xsl:template>
 
              <xsl:template match="comment() | processing-instruction()">
                <xsl:param name="indent" select="''"/>
                <xsl:call-template name="newline"/>
                <xsl:value-of select="$indent"/>
                <xsl:copy />
              </xsl:template>
 
              <xsl:template match="text()">
                <xsl:param name="indent" select="''"/>
                <xsl:call-template name="newline"/>
                <xsl:value-of select="$indent"/>
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:template>
 
              <xsl:template match="text()[normalize-space(.)='']"/>
 
              <xsl:template match="*">
                <xsl:param name="indent" select="''"/>
                <xsl:call-template name="newline"/>
                <xsl:value-of select="$indent"/>
                  <xsl:choose>
                   <xsl:when test="count(child::*) > 0">
                    <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:apply-templates select="*|text()">
                       <xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
                     </xsl:apply-templates>
                     <xsl:call-template name="newline"/>
                     <xsl:value-of select="$indent"/>
                    </xsl:copy>
                   </xsl:when>
                   <xsl:otherwise>
                    <xsl:copy-of select="."/>
                   </xsl:otherwise>
                 </xsl:choose>
              </xsl:template>
            </xsl:stylesheet>).gsub(/^            /, ''))
            if files.empty?
              # If files are empty, either use options[::evaluate]
              input = options[:evaluate] ? StringIO.new(options[:evaluate]) : STDIN
              input.set_encoding(options.fetch(:encoding, Encoding::UTF_8))
              RDF::Microdata::Reader.new(input, **options.merge(rdfa: true)) do |reader|
                reader.rdfa.xpath("//text()").each do |txt|
                  txt.content = txt.content.to_s.strip
                end
                out.puts xsl.apply_to(reader.rdfa).to_s
              end
            else
              files.each do |file|
                RDF::Microdata::Reader.open(file, **options.merge(rdfa: true)) do |reader|
                  reader.rdfa.xpath("//text()").each do |txt|
                    txt.content = txt.content.to_s.strip
                  end
                  out.puts xsl.apply_to(reader.rdfa).to_s
                end
              end
            end
          end
        },
      }
    end
  end
end
