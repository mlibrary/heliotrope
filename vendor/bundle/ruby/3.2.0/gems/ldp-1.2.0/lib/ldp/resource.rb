module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client, :subject
    attr_accessor :content

    def self.for(client, subject, response)
      case
      when response.container?
        Ldp::Container.for client, subject, response
      when response.rdf_source?
        Resource::RdfSource.new client, subject, response
      else
        Resource::BinarySource.new client, subject, response
      end
    end

    def initialize client, subject, response = nil, base_path = ''
      @client = client
      @subject = subject
      @get = response if response.is_a? Faraday::Response and current? response
      @base_path = base_path
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI(subject)
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new client, subject, @get
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      subject.nil? || head == None
    end

    ##
    # Have we retrieved the content already?
    def retrieved_content?
      @get
    end

    ##
    # Get the resource
    def get
      @get ||= client.get(subject)
    end

    def head
      @head ||= begin
        @get || client.head(subject)
                rescue Ldp::NotFound
                  None
      end
    end

    ##
    # Delete the resource
    def delete
      client.delete subject do |req|
        req.headers['If-Unmodified-Since'] = get.last_modified if retrieved_content?
      end
    end

    def save
      new? ? create : update
    end

    ##
    # Create a new resource at the URI
    # @return [RdfSource] the new representation
    # @raise [Ldp::Conflict] if you attempt to call create on an existing resource
    def create &block
      raise Ldp::Conflict, "Can't call create on an existing resource (#{subject})" unless new?
      verb = subject.nil? ? :post : :put
      resp = client.send(verb, (subject || @base_path), content) do |req|
        req.headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
        yield req if block_given?
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
      reload
    end

    ##
    # Update the stored graph
    def update new_content = nil
      new_content ||= content
      resp = client.put subject, new_content do |req|
        req.headers['If-Unmodified-Since'] = get.last_modified if retrieved_content?
        yield req if block_given?
      end
      update_cached_get(resp) if retrieved_content?
      resp
    end

    def current? response = nil
      response ||= @get
      return true if new? and subject.nil?

      new_response = client.head(subject)

      response.headers['ETag'] &&
        response.headers['Last-Modified'] &&
        new_response.headers['ETag'] == response.headers['ETag'] &&
        new_response.headers['Last-Modified'] == response.headers['Last-Modified']
    end

    def update_cached_get(response)
      response = Response.new(response)

      if response.etag.nil? || response.last_modified.nil?
        response = client.head(subject)
      end
      @get.etag = response.etag
      @get.last_modified = response.last_modified
    end

    protected

    def interaction_model
      nil
    end
  end
end
