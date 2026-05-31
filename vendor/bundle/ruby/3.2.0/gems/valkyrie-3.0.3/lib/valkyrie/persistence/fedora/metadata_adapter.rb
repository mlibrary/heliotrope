# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Metadata Adapter for Fedora adapter.
  #
  # @example Instantiate with connection to Fedora.
  #   Valkyrie::Persistence::Fedora::MetadataAdapter.new(
  #     connection: ::Ldp::Client.new("http://localhost:8988/rest"),
  #     base_path: "test_fed",
  #     schema: Valkyrie::Persistence::Fedora::PermissiveSchema.new(title: RDF::URI("http://example.com/title"))
  #   )
  class MetadataAdapter
    attr_reader :connection, :base_path, :schema, :fedora_version

    # @param [Ldp::Client] connection
    # @param [String] base_path
    # @param [Valkyrie::Persistence::Fedora::PermissiveSchema] schema
    # @param [Integer] fedora_version
    def initialize(connection:, base_path: "/", schema: Valkyrie::Persistence::Fedora::PermissiveSchema.new, fedora_version: Valkyrie::Persistence::Fedora::DEFAULT_FEDORA_VERSION)
      @connection = connection
      @base_path = base_path
      @schema = schema
      @fedora_version = fedora_version
    end

    # Construct the query service object using this adapter
    # @return [Valkyrie::Persistence::Fedora::QueryService]
    def query_service
      @query_service ||= Valkyrie::Persistence::Fedora::QueryService.new(adapter: self)
    end

    # Construct the persister object using this adapter
    # @return [Valkyrie::Persistence::Fedora::Persister]
    def persister
      Valkyrie::Persistence::Fedora::Persister.new(adapter: self)
    end

    # Generate the Valkyrie ID for this unique metadata adapter
    # This uses the URL of the Fedora endpoint to ensure that this is unique
    # @return [Valkyrie::ID]
    def id
      @id ||= Valkyrie::ID.new(Digest::MD5.hexdigest(connection_prefix))
    end

    # Construct the factory object used to construct Valkyrie::Resource objects using this adapter
    # @return [Valkyrie::Persistence::Fedora::Persister::ResourceFactory]
    def resource_factory
      Valkyrie::Persistence::Fedora::Persister::ResourceFactory.new(adapter: self)
    end

    # Generate a Valkyrie ID for a given URI
    # @param [RDF::URI] uri the URI for a Fedora resource
    # @return [Valkyrie::ID]
    def uri_to_id(uri)
      Valkyrie::ID.new(CGI.unescape(uri.to_s.gsub(/^.*\//, '')))
    end

    # Generate a URI for a given Valkyrie ID
    # @param [RDF::URI] id the Valkyrie ID
    # @return [RDF::URI]
    def id_to_uri(id)
      prefix = [5, 6].include?(fedora_version) ? "" : "#{pair_path(id)}/"
      RDF::URI("#{connection_prefix}/#{prefix}#{CGI.escape(id.to_s)}")
    end

    # Generate the pairtree path for a given Valkyrie ID
    # @see https://confluence.ucop.edu/display/Curation/PairTree
    # @see https://wiki.duraspace.org/display/FF/Design+-+Identifier+Generation
    # @param [Valkyrie::ID] id the Valkyrie ID
    # @return [Array<String>]
    def pair_path(id)
      id.to_s.split(/[-\/]/).first.split("").each_slice(2).map(&:join).join("/")
    end

    def url_prefix
      connection.http.url_prefix
    end

    # Generate the prefix used in HTTP requests to the Fedora RESTful endpoint
    # @return [String]
    def connection_prefix
      "#{connection.http.url_prefix}/#{base_path}"
    end
  end
end
