module Rack; module RDF
  ##
  # Rack middleware for Linked Data content negotiation.
  #
  # Uses HTTP Content Negotiation to find an appropriate RDF
  # format to serialize any result with a body being `RDF::Enumerable`.
  #
  # Override content negotiation by setting the :format option to
  # {#initialize}.
  #
  # Add a :default option to set a content type to use when nothing else
  # is found.
  #
  # @example
  #     use Rack::RDF::ContentNegotation, :format => :ttl
  #     use Rack::RDF::ContentNegotiation, :format => RDF::NTriples::Format
  #     use Rack::RDF::ContentNegotiation, :default => 'application/rdf+xml'
  #
  # @see https://www4.wiwiss.fu-berlin.de/bizer/pub/LinkedDataTutorial/
  # @see https://www.rubydoc.info/github/rack/rack/master/file/SPEC
  class ContentNegotiation
    DEFAULT_CONTENT_TYPE = "application/n-triples" # N-Triples
    VARY = {'Vary' => 'Accept'}.freeze

    # @return [#call]
    attr_reader :app

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    ##
    # @param  [#call]                  app
    # @param  [Hash{Symbol => Object}] options
    #   Other options passed to writer.
    # @option options [String] :default (DEFAULT_CONTENT_TYPE) Specific content type
    # @option options [RDF::Format, #to_sym] :format Specific RDF writer format to use
    def initialize(app, options)
      @app, @options = app, options
      @options[:default] = (@options[:default] || DEFAULT_CONTENT_TYPE).to_s
    end

    ##
    # Handles a Rack protocol request.
    # Parses Accept header to find appropriate mime-type and sets content_type accordingly.
    #
    # Inserts ordered content types into the environment as `ORDERED_CONTENT_TYPES` if an Accept header is present
    #
    # @param  [Hash{String => String}] env
    # @return [Array(Integer, Hash, #each)] Status, Headers and Body
    # @see    https://rubydoc.info/github/rack/rack/file/SPEC
    def call(env)
      env['ORDERED_CONTENT_TYPES'] = parse_accept_header(env['HTTP_ACCEPT']) if env.has_key?('HTTP_ACCEPT')
      response = app.call(env)
      body = response[2].respond_to?(:body) ? response[2].body : response[2]
      case body
        when ::RDF::Enumerable
          response[2] = body  # Put it back in the response, it might have been a proxy
          serialize(env, *response)
        else response
      end
    end

    ##
    # Serializes an `RDF::Enumerable` response into a Rack protocol
    # response using HTTP content negotiation rules or a specified Content-Type.
    #
    # Passes parameters from Accept header, and Link header to writer.
    #
    # @param  [Hash{String => String}] env
    # @param  [Integer]                status
    # @param  [Hash{String => Object}] headers
    # @param  [RDF::Enumerable]        body
    # @return [Array(Integer, Hash, #each)] Status, Headers and Body
    def serialize(env, status, headers, body)
      result, content_type = nil, nil
      find_writer(env, headers) do |writer, ct, accept_params = {}|
        begin
          # Passes content_type as writer option to allow parameters to be extracted.
          writer_options = @options.merge(
            accept_params: accept_params,
            link: env['HTTP_LINK']
          )
          result, content_type = writer.dump(body, nil, **writer_options), ct.split(';').first
          break
        rescue ::RDF::WriterError
          # Continue to next writer
          ct
        rescue
          ct
        end
      end

      if result
        headers = headers.merge(VARY).merge('Content-Type' => content_type)
        [status, headers, [result]]
      else
        not_acceptable
      end
    end

    protected
    ##
    # Yields an `RDF::Writer` class for the given `env`.
    #
    # If options contain a `:format` key, it identifies the specific format to use;
    # otherwise, if the environment has an HTTP_ACCEPT header, use it to find a writer;
    # otherwise, use the default content type
    #
    # @param  [Hash{String => String}] env
    # @param  [Hash{String => Object}] headers
    # @yield |writer, content_type|
    # @yieldparam [RDF::Writer] writer
    # @yieldparam [String] content_type from accept media-range without parameters
    # @yieldparam [Hash{Symbol => String}] accept_params from accept media-range
    # @see    https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
    def find_writer(env, headers)
      if @options[:format]
        format = @options[:format]
        writer = ::RDF::Writer.for(format.to_sym)
        yield(writer, writer.format.content_type.first) if writer
      elsif env.has_key?('HTTP_ACCEPT')
        content_types = parse_accept_header(env['HTTP_ACCEPT'])
        content_types.each do |content_type|
          find_writer_for_content_type(content_type) do |writer, ct, accept_params|
            # Yields content type with parameters
            yield(writer, ct, accept_params)
          end
        end
      else
        # HTTP/1.1 §14.1: "If no Accept header field is present, then it is
        # assumed that the client accepts all media types"
        find_writer_for_content_type(options[:default]) do |writer, ct|
          # Yields content type with parameters
          yield(writer, ct)
        end
      end
    end

    ##
    # Yields an `RDF::Writer` class for the given `content_type`.
    #
    # Calls `Writer#accept?(content_type)` for matched content type to allow writers to further discriminate on how if to accept content-type with specified parameters.
    #
    # @param  [String, #to_s] content_type
    # @yield |writer, content_type|
    # @yieldparam [RDF::Writer] writer
    # @yieldparam [String] content_type (including media-type parameters)
    def find_writer_for_content_type(content_type)
      ct, *params = content_type.split(';').map(&:strip)
      accept_params = params.inject({}) do |memo, pv|
        p, v = pv.split('=').map(&:strip)
        memo.merge(p.downcase.to_sym => v.sub(/^["']?([^"']*)["']?$/, '\1'))
      end
      formats = ::RDF::Format.each(content_type: ct, has_writer: true).to_a.reverse
      formats.each do |format|
        yield format.writer, (ct || format.content_type.first), accept_params if
          format.writer.accept?(accept_params)
      end
    end

    ##
    # Parses an HTTP `Accept` header, returning an array of MIME content
    # types ordered by the precedence rules defined in HTTP/1.1 §14.1.
    #
    # @param  [String, #to_s] header
    # @return [Array<String>]
    # @see    https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    def parse_accept_header(header)
      entries = header.to_s.split(',')
      entries = entries.map { |e| accept_entry(e) }.sort_by(&:last).map(&:first)
      entries.map { |e| find_content_type_for_media_range(e) }.flatten.compact
    end

    # Returns pair of content_type (including non-'q' parameters)
    # and array of quality, number of '*' in content-type, and number of non-'q' parameters
    def accept_entry(entry)
      type, *options = entry.split(';').map(&:strip)
      quality = 0 # we sort smallest first
      options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
      [options.unshift(type).join(';'), [quality, type.count('*'), 1 - options.size]]
    end

    ##
    # Returns a content type appropriate for the given `media_range`,
    # returns `nil` if `media_range` contains a wildcard subtype
    # that is not mapped.
    #
    # @param  [String, #to_s] media_range
    # @return [String, nil]
    def find_content_type_for_media_range(media_range)
      case media_range.to_s
      when '*/*'
        options[:default]
      when 'text/*'
        'text/turtle'
      when 'application/*'
        'application/ld+json'
      when 'application/json'
        'application/ld+json'
      when 'application/xml'
        'application/rdf+xml'
      when /^([^\/]+)\/\*$/
        nil
      else
        media_range.to_s
      end
    end

    ##
    # Outputs an HTTP `406 Not Acceptable` response.
    #
    # @param  [String, #to_s] message
    # @return [Array(Integer, Hash, #each)]
    def not_acceptable(message = nil)
      http_error(406, message, VARY)
    end

    ##
    # Outputs an HTTP `4xx` or `5xx` response.
    #
    # @param  [Integer, #to_i]         code
    # @param  [String, #to_s]          message
    # @param  [Hash{String => String}] headers
    # @return [Array(Integer, Hash, #each)]
    def http_error(code, message = nil, headers = {})
      message = http_status(code) + (message.nil? ? "\n" : " (#{message})\n")
      [code, {'Content-Type' => "text/plain"}.merge(headers), [message]]
    end

    ##
    # Returns the standard HTTP status message for the given status `code`.
    #
    # @param  [Integer, #to_i] code
    # @return [String]
    def http_status(code)
      [code, Rack::Utils::HTTP_STATUS_CODES[code]].join(' ')
    end
  end # class ContentNegotiation
end; end # module Rack::RDF
