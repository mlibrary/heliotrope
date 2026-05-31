##
# LDP client for presenting an ORM on top of an LDP resource
module Ldp
  class Client
    require 'ldp/client/methods'
    require 'ldp/client/prefer_headers'
    include Ldp::Client::Methods

    attr_reader :options

    def initialize(*args)
      http_client, options = if args.length == 2
                               args
                             elsif args.length == 1 && args.first.is_a?(Faraday::Connection)
                               [args.first, {}]
                             elsif args.length == 1
                               [nil, args.first]
                             else
                               raise ArgumentError
                             end

      @options = options

      initialize_http_client(http_client || options)
    end

    # Find or initialize a new LDP resource by URI
    def find_or_initialize(subject, options = {})
      data = get(subject, options)

      Ldp::Resource.for(self, subject, data)
    end

    def logger
      Ldp.logger
    end
  end
end
