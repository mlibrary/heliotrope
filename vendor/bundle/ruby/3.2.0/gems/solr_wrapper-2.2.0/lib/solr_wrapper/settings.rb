require 'delegate'
require 'faraday'

module SolrWrapper
  # Configuraton that comes from static and dynamic sources.
  class Settings < Delegator

    def __getobj__
      @static_config # return object we are delegating to, required
    end

    alias static_config __getobj__

    def __setobj__(obj)
      @static_config = obj
    end

    def initialize(static_config)
      super
      @static_config = static_config
    end

    ##
    # Get the host this Solr instance is bound to
    def host
      '127.0.0.1'
    end

    def zookeeper_host
      @zookeeper_host ||= static_config.zookeeper_port
      @zookeeper_host ||= host
    end

    ##
    # Get the port this Solr instance is running at
    def port
      @port ||= static_config.port
      @port ||= random_open_port.to_s
    end

    def zookeeper_port
      @zookeeper_port ||= static_config.zookeeper_port
      @zookeeper_port ||= "#{port.to_i + 1000}"
    end

    ##
    # Get a (likely) URL to the solr instance
    def url
      "http://#{host}:#{port}/solr/"
    end

    def instance_dir
      @instance_dir ||= static_config.instance_dir
      @instance_dir ||= File.join(tmpdir, File.basename(download_url, ".zip"))
    end

    def managed?
      File.exist?(instance_dir)
    end

    def download_url
      @download_url ||= static_config.url
      @download_url ||= default_download_url
    end

    def solr_zip_path
      @solr_zip_path ||= static_config.solr_zip_path
      @solr_zip_path ||= default_solr_zip_path
    end

    def version_file
      static_config.version_file || File.join(instance_dir, "VERSION")
    end

    def solr_binary
      File.join(instance_dir, "bin", "solr")
    end

    def tmp_save_dir
      @tmp_save_dir ||= Dir.mktmpdir
    end

    def default_download_url
      static_config.mirror_url
    end

    private

      def tmpdir
        if defined?(Rails) && Rails.root
          File.join(Rails.root, 'tmp')
        else
          Dir.tmpdir
        end
      end

      def default_solr_zip_path
        File.join(download_dir, File.basename(download_url))
      end

      def download_dir
        @download_dir ||= static_config.download_dir
        FileUtils.mkdir_p @download_dir
        @download_dir
      end

      def random_open_port
        socket = Socket.new(:INET, :STREAM, 0)
        begin
          socket.bind(Addrinfo.tcp('127.0.0.1', 0))
          socket.local_address.ip_port
        ensure
          socket.close
        end
      end
  end
end
