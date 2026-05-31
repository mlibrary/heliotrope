module SolrWrapper
  class ChecksumValidator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def clean!
      path = checksum_path(algorithm)
      FileUtils.remove_entry(path) if File.exist? path
    end

    def validate?(file)
      return true if config.validate == false
      Digest.const_get(algorithm.upcase).file(file).hexdigest == expected_sum(algorithm)
    end

    def validate!(file)
      unless validate? file
        raise "Checksum mismatch" unless config.ignore_checksum
      end
    end

    private

      def checksumurl(suffix)
        if config.default_download_url == config.static_config.archive_download_url
          "#{config.default_download_url}.#{suffix}"
        else
          "http://www.us.apache.org/dist/lucene/solr/#{config.static_config.version}/solr-#{config.static_config.version}.zip.#{suffix}"
        end
      end

      def checksum_path(suffix)
        File.join(config.download_dir, File.basename(checksumurl(suffix)))
      end

      def expected_sum(alg)
        config.checksum || read_file(alg)
      end

      def read_file(alg)
        open(checksumfile(alg)).read.split(" ").first
      end

      def checksumfile(alg)
        path = checksum_path(alg)
        unless File.exist? path
          Downloader.fetch_with_progressbar checksumurl(alg), path
        end
        path
      end

      def algorithm
        return config.static_config.algorithm if config.static_config.algorithm
        return 'sha1' if config.static_config.version =~ /^[1-6]/ || config.static_config.version =~ /^[7]\.[0-4]/

        'sha512'
      end
  end
end
