require 'open-uri'
require 'active_support/core_ext/file/atomic'

module Riiif
  class HttpFileResolver
    # Set a lambda that maps the first parameter (id) to a URL
    # Example:
    #
    # resolver = Riiif::HttpFileResolver.new
    # resolver.id_to_uri = lambda do |id|
    #  "http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/#{id}.jpg/600px-#{id}.jpg"
    # end
    #
    attr_accessor :id_to_uri
    attr_accessor :basic_auth_credentials
    attr_accessor :cache_path

    def initialize(cache_path: 'tmp/network_files')
      @cache_path = cache_path
    end

    def find(id)
      remote = RemoteFile.new(uri(id),
                              cache_path: cache_path,
                              basic_auth_credentials: basic_auth_credentials)
      Riiif::File.new(remote.fetch)
    end

    class RemoteFile
      include ActiveSupport::Benchmarkable
      delegate :logger, to: :Rails
      attr_reader :url, :cache_path
      def initialize(url, options = {})
        @url = url
        @options = options
      end

      def cache_path
        @options.fetch(:cache_path)
      end

      def basic_auth_credentials
        @options[:basic_auth_credentials]
      end

      def fetch
        download_file unless ::File.exist?(file_name)
        file_name
      end

      private

        def ext
          @ext ||= ::File.extname(URI.parse(url).path)
        end

        def file_name
          @cache_file_name ||= ::File.join(cache_path, Digest::MD5.hexdigest(url) + ext.to_s)
        end

        def download_file
          ensure_cache_path(::File.dirname(file_name))
          benchmark("Riiif downloaded #{url}") do
            ::File.atomic_write(file_name, cache_path) do |local|
              begin
                handler.open(url, **download_opts) do |remote|
                  while chunk = remote.read(8192)
                    local.write(chunk)
                  end
                end
              rescue OpenURI::HTTPError => e
                raise ImageNotFoundError, e.message
              end
            end
          end
        end

        # Get a hash of options for passing to Kernel::open
        # This is the primary pathway for passing basic auth credentials
        def download_opts
          basic_auth_credentials ? { http_basic_authentication: basic_auth_credentials } : {}
        end

        # Make sure a file path's directories exist.
        def ensure_cache_path(path)
          FileUtils.makedirs(path) unless ::File.exist?(path)
        end

        def handler
          if url.match?(URI.regexp)
            URI
          else
            Kernel
          end
        end
    end

    protected

      def uri(id)
        raise 'Must set the id_to_uri lambda' if id_to_uri.nil?
        id_to_uri.call(id)
      end
  end
end
