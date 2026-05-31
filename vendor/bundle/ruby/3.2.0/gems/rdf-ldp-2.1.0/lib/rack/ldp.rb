require 'rack'
begin
  require 'linkeddata'
rescue LoadError
  require 'rdf/turtle'
  require 'json/ld'
end

require 'rack/linkeddata'
require 'rdf/ldp'

module Rack
  ##
  # Provides Rack middleware for handling Linked Data Platform requirements
  # when passed {RDF::LDP::Resource} and its subclasses as response objects.
  #
  # Response objects that are not an {RDF::LDP::Resource} are passed over
  # without alteration, allowing server implementers to mix LDP interaction
  # patterns with others on the same server.
  #
  # The suite can be mix-and-matched as needed. This allows easy swap in of
  # custom handlers for parts of the behavior. It is recommended that you use
  # {Rack::LDP::ContentNegotiation}, {Rack::LDP::Errors}, {Rack::LDP::Responses}
  # and {Rack::LDP::Reousets} as the outer middleware layers. With these in
  # place, you can handle requests as needed in your application, giving
  # responses conforming to the core {RDF::LDP::Resource} interface.
  #
  # @example
  #   run Rack:;Builder.new do
  #     use Rack::LDP::ContentNegotiation
  #     use Rack::LDP::Errors
  #     use Rack::LDP::Responses
  #     use Rack::LDP::Requests
  #     # ...
  #   end
  #
  # @see https://www.w3.org/TR/ldp/ the LDP specification
  module LDP
    ##
    # Catches and handles RequestErrors thrown by RDF::LDP
    class Errors
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Catches {RDF::LDP::RequestError} and its various subclasses, building an
      # appropriate response
      #
      # @param [Array] env  a rack env array
      # @return [Array]  a rack env array with added headers
      def call(env)
        @app.call(env)
      rescue ::RDF::LDP::RequestError => err
        return [err.status, err.headers, [err.message]]
      end
    end

    ##
    # Converts RDF::LDP::Resource} into appropriate responses
    class Responses
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Converts the response body from {RDF::LDP::Resource} form to a Graph
      def call(env)
        status, headers, response = @app.call(env)

        if response.is_a? ::RDF::LDP::Resource
          new_response = response.to_response
          response.close if response.respond_to? :close
          response = new_response
        end

        [status, headers, response]
      end
    end

    ##
    #
    class Requests
      ##
      # @param  [#call] app
      def initialize(app)
        @app = app
      end

      ##
      # Handles a Rack protocol request. Sends appropriate request to the
      # object, alters response accordingly.
      #
      # @param [Array] env  a rack env array
      # @return [Array]  a rack env array with added headers
      def call(env)
        status, headers, response = @app.call(env)
        return [status, headers, response] unless
          response.is_a? ::RDF::LDP::Resource

        response
          .send(:request, env['REQUEST_METHOD'].to_sym, status, headers, env)
      end
    end

    ##
    # Specializes `Rack::LinkedData::ContentNegotiation`, making the default
    # return type 'text/turtle'.
    #
    # @see Rack::LinkedData::ContentNegotiation, making
    class ContentNegotiation < Rack::LinkedData::ContentNegotiation
      DEFAULT_PREFIXES =
        Hash[*::RDF::Vocabulary.map { |v| [v.__prefix__, v.to_uri] }.flatten]
        .freeze

      def initialize(app, options = {})
        options[:default] ||= 'text/turtle'
        options[:prefixes] ||= DEFAULT_PREFIXES.dup
        super
      end

      ##
      # The default LinkedData Conneg doesn't support wildcard operators. We
      # patch in support for 'text/*' manually, giving Turtle. This should be
      # considered helpful by LDP clients.
      #
      # @see Rack::LinkedData::ContentNegotiation#find_writer_for_content_type
      def find_writer_for_content_type(content_type)
        return [::RDF::Writer.for(:ttl), 'text/turtle'] if
          content_type == 'text/*'
        super
      end
    end
  end
end
