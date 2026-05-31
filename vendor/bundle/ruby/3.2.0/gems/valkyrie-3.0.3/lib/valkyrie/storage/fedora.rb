# frozen_string_literal: true
module Valkyrie::Storage
  # Implements the DataMapper Pattern to store binary data in fedora
  class Fedora
    attr_reader :connection, :base_path, :fedora_version
    PROTOCOL = 'fedora://'
    SLASH = '/'

    # @param [Ldp::Client] connection
    def initialize(connection:, base_path: "/", fedora_version: Valkyrie::Persistence::Fedora::DEFAULT_FEDORA_VERSION)
      @connection = connection
      @base_path = base_path
      @fedora_version = fedora_version
    end

    # @param id [Valkyrie::ID]
    # @return [Boolean] true if this adapter can handle this type of identifer
    def handles?(id:)
      id.to_s.start_with?(PROTOCOL)
    end

    # Return the file associated with the given identifier
    # @param id [Valkyrie::ID]
    # @return [Valkyrie::StorageAdapter::StreamFile]
    # @raise Valkyrie::StorageAdapter::FileNotFound if nothing is found
    def find_by(id:)
      Valkyrie::StorageAdapter::StreamFile.new(id: id, io: response(id: id))
    end

    # @param file [IO]
    # @param original_filename [String]
    # @param resource [Valkyrie::Resource]
    # @param content_type [String] content type of file (e.g. 'image/tiff') (default='application/octet-stream')
    # @param resource_uri_transformer [Lambda] transforms the resource's id (e.g. 'DDS78RK') into a uri (optional)
    # @param extra_arguments [Hash] additional arguments which may be passed to other adapters
    # @return [Valkyrie::StorageAdapter::StreamFile]
    def upload(file:, original_filename:, resource:, content_type: "application/octet-stream", # rubocop:disable Metrics/ParameterLists
               resource_uri_transformer: default_resource_uri_transformer, **_extra_arguments)
      identifier = resource_uri_transformer.call(resource, base_url) + '/original'
      sha1 = [5, 6].include?(fedora_version) ? "sha" : "sha1"
      connection.http.put do |request|
        request.url identifier
        request.headers['Content-Type'] = content_type
        request.headers['Content-Length'] = file.length.to_s
        request.headers['Content-Disposition'] = "attachment; filename=\"#{original_filename}\""
        request.headers['digest'] = "#{sha1}=#{Digest::SHA1.file(file)}"
        request.headers['link'] = "<http://www.w3.org/ns/ldp#NonRDFSource>; rel=\"type\""
        io = Faraday::UploadIO.new(file, content_type, original_filename)
        request.body = io
      end
      find_by(id: Valkyrie::ID.new(identifier.to_s.sub(/^.+\/\//, PROTOCOL)))
    end

    # Delete the file in Fedora associated with the given identifier.
    # @param id [Valkyrie::ID]
    def delete(id:)
      connection.http.delete(fedora_identifier(id: id))
    end

    class IOProxy
      # @param response [Ldp::Resource::BinarySource]
      attr_reader :size
      def initialize(source)
        @source = source
        @size = source.size
      end
      delegate :each, :read, :rewind, to: :io

      # There is no streaming support in faraday (https://github.com/lostisland/faraday/pull/604)
      # @return [StringIO]
      def io
        @io ||= StringIO.new(@source)
      end
    end
    private_constant :IOProxy

    # Translate the Valkrie ID into a URL for the fedora file
    # @return [RDF::URI]
    def fedora_identifier(id:)
      identifier = id.to_s.sub(PROTOCOL, "#{connection.http.scheme}://")
      RDF::URI(identifier)
    end

    private

    # @return [IOProxy]
    def response(id:)
      response = connection.http.get(fedora_identifier(id: id))
      raise Valkyrie::StorageAdapter::FileNotFound unless response.success?
      IOProxy.new(response.body)
    end

    def default_resource_uri_transformer
      lambda do |resource, base_url|
        id = CGI.escape(resource.id.to_s)
        RDF::URI.new(base_url + id)
      end
    end

    def base_url
      pre_divider = base_path.starts_with?(SLASH) ? '' : SLASH
      post_divider = base_path.ends_with?(SLASH) ? '' : SLASH
      "#{connection.http.url_prefix}#{pre_divider}#{base_path}#{post_divider}"
    end
  end
end
