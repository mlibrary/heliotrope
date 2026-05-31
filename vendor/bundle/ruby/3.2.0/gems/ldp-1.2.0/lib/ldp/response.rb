require 'uri'

module Ldp
  class Response
    extend Forwardable

    TYPE = 'type'.freeze

    attr_reader :response

    attr_writer :etag, :last_modified

    # @param response [Faraday::Response]
    def initialize(response)
      @response = response
    end

    ##
    # Extract the Link: headers from the HTTP resource
    def links
      @links ||= begin
        h = {}
        Array(headers['Link'.freeze]).map { |x| x.split(','.freeze) }.flatten.inject(h) do |memo, header|
          m = header.match(/<(?<link>.*)>;\s?rel="(?<rel>[^"]+)"/)
          if m
            memo[m[:rel]] ||= []
            memo[m[:rel]] << m[:link]
          end

          memo
        end
      end
    end

    def applied_preferences
      h = {}

      Array(headers['Preference-Applied'.freeze]).map { |x| x.split(",") }.flatten.inject(h) do |memo, header|
        m = header.match(/(?<key>[^=;]*)(=(?<value>[^;,]*))?(;\s*(?<params>[^,]*))?/)
        includes = (m[:params].match(/include="(?<include>[^"]+)"/)[:include] || "").split(" ")
        omits = (m[:params].match(/omit="(?<omit>[^"]+)"/)[:omit] || "").split(" ")
        memo[m[:key]] = { value: m[:value], includes: includes, omits: omits }
      end
    end

    ##
    # Is the response an LDP resource?

    def resource?
      Array(links[TYPE]).include? RDF::Vocab::LDP.Resource.to_s
    end

    ##
    # Is the response an LDP container?
    def container?
      [
        RDF::Vocab::LDP.BasicContainer,
        RDF::Vocab::LDP.DirectContainer,
        RDF::Vocab::LDP.IndirectContainer
      ].any? { |x| Array(links[TYPE]).include? x.to_s }
    end

    ##
    # Is the response an LDP RDFSource?
    #   ldp:Container is a subclass of ldp:RDFSource
    def rdf_source?
      container? || Array(links[TYPE]).include?(RDF::Vocab::LDP.RDFSource)
    end

    def dup
      super.tap do |new_resp|
        unless new_resp.instance_variable_get(:@graph).nil?
          new_resp.remove_instance_variable(:@graph)
        end
      end
    end

    ##
    # Get the subject for the response
    def subject
      @subject ||= if has_page?
                     graph.first_object [page_subject, RDF::Vocab::LDP.pageOf, nil]
                   else
                     page_subject
                   end
    end

    ##
    # Get the URI to the response
    def page_subject
      @page_subject ||= RDF::URI.new response.env[:url]
    end

    ##
    # Is the response paginated?
    def has_page?
      rdf_source? && graph.has_statement?(RDF::Statement.new(page_subject, RDF.type, RDF::Vocab::LDP.Page))
    end

    def body
      response.body
    end

    ##
    # Get the graph for the resource (or a blank graph if there is no metadata for the resource)
    def graph
      @graph ||= RDF::Graph.new << reader
    end

    def reader(&block)
      reader_for_content_type.new(body, base_uri: page_subject, &block)
    end

    ##
    # @deprecated use {#graph} instead
    def each_statement(&block)
      reader do |reader|
        reader.each_statement(&block)
      end
    end

    ##
    # Extract the ETag for the resource
    def etag
      @etag ||= headers['ETag'.freeze]
    end

    ##
    # Extract the last modified header for the resource
    def last_modified
      @last_modified ||= headers['Last-Modified'.freeze]
    end

    ##
    # Extract the Link: rel="type" headers for the resource
    def types
      Array(links[TYPE])
    end

    RETURN = 'return'.freeze

    def includes? preference
      key = Ldp.send("prefer_#{preference}") if Ldp.respond_to("prefer_#{preference}")
      key ||= preference
      preferences[RETURN][:includes].include?(key) || !preferences["return"][:omits].include?(key)
    end

    def minimal?
      preferences[RETURN][:value] == "minimal"
    end

    ##
    # Statements about the page
    def page
      @page_graph ||= begin
        page_graph = RDF::Graph.new
        page_graph << graph.query([page_subject, nil, nil]) if resource?
        page_graph
      end
    end

    ##
    # Is there a next page?
    def has_next?
      next_page != nil
    end

    ##
    # Get the URI for the next page
    def next_page
      graph.first_object [page_subject, RDF::Vocab::LDP.nextPage, nil]
    end

    ##
    # Get the URI to the first page
    def first_page
      if links['first']
        RDF::URI.new links['first']
      elsif graph.has_statement? RDf::Statement.new(page_subject, RDF::Vocab::LDP.nextPage, nil)
        subject
      end
    end

    def content_type
      headers['Content-Type']
    end

    def content_length
      headers['Content-Length'].to_i
    end

    def content_disposition_filename
      filename = content_disposition_attributes['filename']
      CGI.unescape(filename) if filename
    end

    private

    def content_disposition_attributes
      parts = headers['Content-Disposition'].split(/;\s*/).collect { |entry| entry.split(/\s*=\s*/) }
      entries = parts.collect do |part|
        value = part[1].respond_to?(:sub) ? part[1].sub(%r{^"(.*)"$}, '\1') : part[1]
        [part[0], value]
      end
      Hash[entries]
    end

    def headers
      response.headers
    end

    def reader_for_content_type
      content_type = content_type || 'text/turtle'
      content_type = Array(content_type).first
      RDF::Reader.for(content_type: content_type)
    end
  end
end
