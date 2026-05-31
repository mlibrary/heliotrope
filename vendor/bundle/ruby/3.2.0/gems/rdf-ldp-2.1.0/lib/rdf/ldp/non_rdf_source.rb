require 'rdf/ldp/storage_adapters/file_storage_adapter'

module RDF::LDP
  ##
  # A NonRDFSource describes a `Resource` whose response body is a format other
  # than an RDF serialization. The persistent state of the resource, as
  # represented by the body, is persisted to an IO stream provided by a
  # `RDF::LDP::NonRDFSource::StorageAdapter` given by `#storage`.
  #
  # In addition to the properties stored by the `RDF::LDP::Resource#metagraph`,
  # `NonRDFSource`s also store a content type (format).
  #
  # When a `NonRDFSource` is created, it also creates an `RDFSource` which
  # describes it. This resource is created at the URI in `#description_uri`,
  # the resource itself is returned by `#description`.
  #
  # @see RDF::LDP::Resource
  # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-non-rdf-source for
  #   a definition of NonRDFSource in LDP
  class NonRDFSource < Resource
    attr_reader :storage

    # Use the default filesystem-based storage adapter
    DEFAULT_ADAPTER = RDF::LDP::NonRDFSource::FileStorageAdapter

    # Use DC elements format
    FORMAT_TERM = RDF::Vocab::DC11.format.freeze

    ##
    # @param [RDF::URI] subject_uri
    # @param [RDF::Queryable] data
    # @param [StorageAdapter] storage_adapter a class implementing the StorageAdapter interface
    #
    # @see RDF::LDP::Resource#initialize
    def initialize(subject_uri,
                   data            = RDF::Repository.new,
                   storage_adapter = DEFAULT_ADAPTER)
      data ||= RDF::Repository.new # allows explict `nil` pass
      @storage = storage_adapter.new(self)
      super(subject_uri, data)
    end

    ##
    # @return [RDF::URI] uri with lexical representation
    #   'http://www.w3.org/ns/ldp#NonRDFSource'
    #
    # @see https://www.w3.org/TR/ldp/#dfn-linked-data-platform-non-rdf-source
    def self.to_uri
      RDF::Vocab::LDP.NonRDFSource
    end

    ##
    # @return [Boolean] whether this is an ldp:NonRDFSource
    def non_rdf_source?
      true
    end

    ##
    # @param [IO, File] input  input (usually from a Rack env's
    #   `rack.input` key) that will be read into the NonRDFSource
    # @param [#to_s] c_type  a MIME content_type used as a content type
    #   for the created NonRDFSource
    #
    # @raise [RDF::LDP::RequestError] when saving the NonRDFSource
    #
    # @return [RDF::LDP::NonRDFSource] self
    #
    # @see RDF::LDP::Resource#create
    def create(input, c_type)
      storage.io { |io| IO.copy_stream(input, io) }
      super
      self.content_type = c_type

      RDFSource.new(description_uri, @data)
               .create(StringIO.new, 'application/n-triples')

      self
    end

    ##
    # @see RDF::LDP::Resource#update
    def update(input, c_type)
      storage.io { |io| IO.copy_stream(input, io) }
      super
      self.content_type = c_type
      self
    end

    ##
    # Deletes the LDP-NR contents from the storage medium and marks the
    # resource as destroyed.
    #
    # @see RDF::LDP::Resource#destroy
    def destroy
      super
      storage.delete
    end

    ##
    # @raise [RDF::LDP::NotFound] if the describedby resource doesn't exist
    #
    # @return [RDF::LDP::RDFSource] resource describing this resource
    def description
      RDF::LDP::Resource.find(description_uri, @data)
    end

    ##
    # @return [RDF::URI] uri for this resource's associated RDFSource
    def description_uri
      subject_uri / '.well-known' / 'desc'
    end

    ##
    # Sets the MIME type for the resource in `metagraph`.
    #
    # @param [String] content_type a string representing the content type for this LDP-NR.
    #   This SHOULD be a regisered MIME type.
    #
    # @return [StorageAdapter] the content type
    def content_type=(content_type)
      metagraph.delete([subject_uri, FORMAT_TERM])
      metagraph <<
        RDF::Statement(subject_uri, FORMAT_TERM, content_type)
    end

    ##
    # @return [StorageAdapter] this resource's content type
    def content_type
      format_triple = metagraph.first([subject_uri, FORMAT_TERM, :format])
      format_triple.nil? ? nil : format_triple.object.object
    end

    ##
    # @return [#each] the response body. This is normally the StorageAdapter's
    #   IO object in read and binary mode.
    #
    # @raise [RDF::LDP::RequestError] when the request fails
    def to_response
      exists? && !destroyed? ? storage.io : []
    end

    private

    ##
    # Process & generate response for PUT requsets.
    def put(_status, headers, env)
      raise(PreconditionFailed, 'Etag invalid') if
        env.key?('HTTP_IF_MATCH') && !match?(env['HTTP_IF_MATCH'])

      if exists?
        update(env['rack.input'], env['CONTENT_TYPE'])
        headers = update_headers(headers)
        [200, headers, self]
      else
        create(env['rack.input'], env['CONTENT_TYPE'])
        [201, update_headers(headers), self]
      end
    end

    ##
    # @see RDF::LDP::Resource#update_headers
    def update_headers(headers)
      headers['Content-Type'] = content_type
      super
    end

    def link_headers
      super << "<#{description_uri}>;rel=\"describedby\""
    end
  end
end
