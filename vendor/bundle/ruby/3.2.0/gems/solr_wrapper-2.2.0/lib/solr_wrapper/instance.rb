require 'digest'
require 'fileutils'
require 'json'
require 'open-uri'
require 'securerandom'
require 'socket'
require 'stringio'
require 'tmpdir'
require 'zip'
require 'erb'
require 'yaml'
require 'retriable'

module SolrWrapper
  class Instance
    attr_reader :config

    ##
    # @param [Hash] options
    # @option options [String] :url
    # @option options [String] :instance_dir Directory to store the solr index files
    # @option options [String] :version Solr version to download and install
    # @option options [String] :port port to run Solr on
    # @option options [Boolean] :cloud Run solr in cloud mode
    # @option options [String] :version_file Local path to store the currently installed version
    # @option options [String] :download_dir Local directory to store the downloaded Solr zip and its checksum file in (overridden by :solr_zip_path)
    # @option options [String] :solr_zip_path Local path for storing the downloaded Solr zip file
    # @option options [Boolean] :validate Should solr_wrapper download a new checksum and (re-)validate the zip file? (default: trueF)
    # @option options [String] :checksum Path/URL to checksum
    # @option options [String] :solr_xml Path to Solr configuration
    # @option options [String] :extra_lib_dir Path to directory containing extra libraries to copy into instance_dir/lib
    # @option options [Boolean] :verbose return verbose info when running solr commands
    # @option options [Boolean] :ignore_checksum
    # @option options [Hash] :solr_options
    # @option options [Hash] :env
    # @option options [String] :config
    def initialize(options = {})
      @config = Settings.new(Configuration.new(options))
    end

    def host
      config.host
    end

    def port
      config.port
    end

    def url
      config.url
    end

    def instance_dir
      config.instance_dir
    end

    def version
      config.version
    end

    def wrap(&_block)
      extract_and_configure
      start
      yield self
    ensure
      stop
    end

    ##
    # Start Solr and wait for it to become available
    def start
      extract_and_configure
      if config.managed?
        exec('start', p: port, c: config.cloud)

        # Wait for solr to start
        unless status
          sleep config.poll_interval
        end

        after_start
      end
    end

    ##
    # Stop Solr and wait for it to finish exiting
    def stop
      if config.managed? && started?
        exec('stop', p: port)
        wait
      end
    end

    ##
    # Stop Solr and wait for it to finish exiting
    def restart
      if config.managed? && started?
        exec('restart', p: port, c: config.cloud)
      end
    end

    ##
    # Check the status of a managed Solr service
    def status
      return true unless config.managed?

      out = exec('status').read
      out =~ /running on port #{port}/
    rescue
      false
    end

    def pid
      return unless config.managed?

      @pid ||= begin
        out = exec('status').read
        out.match(/process (?<pid>\d+) running on port #{port}/) do |m|
          m[:pid].to_i
        end
      end
    rescue
      nil
    end

    ##
    # Is Solr running?
    def started?
      !!status
    end

    def wait
      while (Process.getpgid(pid) rescue status)
        sleep config.poll_interval
      end
    end

    ##
    # Create a new collection in solr
    # @param [Hash] options
    # @option options [String] :name
    # @option options [String] :dir
    def create(options = {})
      options[:name] ||= SecureRandom.hex

      create_options = { p: port }
      create_options[:c] = options[:name] if options[:name]
      create_options[:n] = options[:config_name] if options[:config_name]
      create_options[:d] = options[:dir] if options[:dir]

      Retriable.retriable do
        raise "Not started yet" unless started?
      end

      # short-circuit if we're using persisted data with an existing core/collection
      return if options[:persist] && create_options[:c] && client.exists?(create_options[:c])

      exec("create", create_options)

      options[:name]
    end

    ##
    # Update the collection configuration in zookeeper
    # @param [Hash] options
    # @option options [String] :config_name
    # @option options [String] :dir
    def upconfig(options = {})
      options[:name] ||= SecureRandom.hex
      options[:zkhost] ||= zkhost

      upconfig_options = { upconfig: true, n: options[:name] }
      upconfig_options[:d] = options[:dir] if options[:dir]
      upconfig_options[:z] = options[:zkhost] if options[:zkhost]

      exec 'zk', upconfig_options

      options[:name]
    end

    ##
    # Copy the collection configuration from zookeeper to a local directory
    # @param [Hash] options
    # @option options [String] :config_name
    # @option options [String] :dir
    def downconfig(options = {})
      options[:name] ||= SecureRandom.hex
      options[:zkhost] ||= zkhost

      downconfig_options = { downconfig: true, n: options[:name] }
      downconfig_options[:d] = options[:dir] if options[:dir]
      downconfig_options[:z] = options[:zkhost] if options[:zkhost]

      exec 'zk', downconfig_options

      options[:name]
    end

    ##
    # Create a new collection in solr
    # @param [String] name collection name
    def delete(name, _options = {})
      exec("delete", c: name, p: port)
    end

    ##
    # Create a new collection, run the block, and then clean up the collection
    # @param [Hash] options
    # @option options [String] :name
    # @option options [String] :dir
    def with_collection(options = {})
      options = config.collection_options.merge(options)
      return yield if options.empty?

      name = create(options)
      begin
        yield name
      ensure
        delete name unless options[:persist]
      end
    end

    ##
    # Clean up any files solr_wrapper may have downloaded
    def clean!
      stop
      remove_instance_dir!
      FileUtils.remove_entry(config.download_dir, true) if File.exist?(config.download_dir)
      FileUtils.remove_entry(config.tmp_save_dir, true) if File.exist? config.tmp_save_dir
      checksum_validator.clean!
      FileUtils.remove_entry(config.version_file) if File.exist? config.version_file
    end

    ##
    # Clean up any files in the Solr instance dir
    def remove_instance_dir!
      FileUtils.remove_entry(instance_dir, true) if File.exist? instance_dir
    end

    def configure
      raise_error_unless_extracted
      FileUtils.cp config.solr_xml, File.join(config.instance_dir, 'server', 'solr', 'solr.xml') if config.solr_xml
      FileUtils.cp_r File.join(config.extra_lib_dir, '.'), File.join(config.instance_dir, 'server', 'solr', 'lib') if config.extra_lib_dir
    end

    def extract_and_configure
      extract.tap { configure }
    end

    # rubocop:disable Lint/RescueException

    # extract a copy of solr to instance_dir
    # Does noting if solr already exists at instance_dir
    # @return [String] instance_dir Directory where solr has been installed
    def extract
      return config.instance_dir if extracted?

      zip_path = download

      begin
        Zip::File.open(zip_path) do |zip_file|
          # Handle entries one by one
          zip_file.each do |entry|
            dest_file = File.join(config.tmp_save_dir, entry.name)
            FileUtils.remove_entry(dest_file, true)
            entry.extract(dest_file)
          end
        end

      rescue Exception => e
        abort "Unable to unzip #{zip_path} into #{config.tmp_save_dir}: #{e.message}"
      end

      begin
        FileUtils.remove_dir(config.instance_dir, true)
        FileUtils.cp_r File.join(config.tmp_save_dir, File.basename(config.download_url, ".zip")), config.instance_dir
        self.extracted_version = config.version
        FileUtils.chmod 0755, config.solr_binary
      rescue Exception => e
        abort "Unable to copy #{config.tmp_save_dir} to #{config.instance_dir}: #{e.message}"
      end

      config.instance_dir
    ensure
      FileUtils.remove_entry config.tmp_save_dir if File.exist? config.tmp_save_dir
    end
    # rubocop:enable Lint/RescueException

    protected

    def extracted?
      File.exist?(config.solr_binary) && extracted_version == config.version
    end

    def download
      unless File.exist?(config.solr_zip_path) && checksum_validator.validate?(config.solr_zip_path)
        Downloader.fetch_with_progressbar config.download_url, config.solr_zip_path
        checksum_validator.validate! config.solr_zip_path
      end
      config.solr_zip_path
    end

    ##
    # Run a bin/solr command
    # @param [String] cmd command to run
    # @param [Hash] options key-value pairs to transform into command line arguments
    # @return [StringIO] an IO object for the executed shell command
    # @see https://github.com/apache/lucene-solr/blob/trunk/solr/bin/solr
    # If you want to pass a boolean flag, include it in the +options+ hash with its value set to +true+
    # the key will be converted into a boolean flag for you.
    # @example start solr in cloud mode on port 8983
    #   exec('start', {p: '8983', c: true})
    def exec(cmd, options = {})
      stringio = StringIO.new
      # JRuby uses Popen4
      command_runner = IO.respond_to?(:popen4) ? Popen4Runner : PopenRunner
      runner = command_runner.new(cmd, options, config)
      exit_status = runner.run(stringio)

      if exit_status != 0 && cmd != 'status'
        raise "Failed to execute solr #{cmd}: #{stringio.read}. Further information may be available in #{instance_dir}/server/logs"
      end

      stringio
    end

    private

    def checksum_validator
      @checksum_validator ||= ChecksumValidator.new(config)
    end

    def after_start
      create_configsets if config.cloud
    end

    def create_configsets
      config.configsets.each do |configset|
        upconfig(configset)
      end
    end

    def extracted_version
      File.read(config.version_file).strip if File.exist? config.version_file
    end

    def extracted_version=(version)
      File.open(config.version_file, "w") do |f|
        f.puts version
      end
    end

    def zkhost
      "#{config.zookeeper_host}:#{config.zookeeper_port}" if config.cloud
    end

    def client
      SolrWrapper::Client.new(url)
    end

    def raise_error_unless_extracted
      raise RuntimeError, "there is no solr instance at #{config.instance_dir}.  Run SolrWrapper.extract first." unless extracted?
    end
  end
end
