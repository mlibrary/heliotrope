# frozen_string_literal: true

require "ostruct"
require "logger"
require "yaml"

# Module for database interactions for Keycard.
module Keycard::DB
  # Any error with the database that Keycard itself detects but cannot handle.
  class DatabaseError < StandardError; end

  CONNECTION_ERROR = "The Keycard database is not initialized. Call initialize! first."

  ALREADY_CONNECTED = "Already connected; refusing to connect to another database."

  MISSING_CONFIG = <<~MSG
    KEYCARD_DATABASE_URL and DATABASE_URL are both missing and a connection
    has not been configured. Cannot connect to the Keycard database.
    See Keycard::DB.connect! for help.
  MSG

  LOAD_ERROR = <<~MSG
    Error loading Keycard database models.
    Verify connection information and that the database is migrated.
  MSG

  SCHEMA_HEADER = "# Keycard Database Version\n"

  class << self
    # Initialize Keycard
    #
    # This connects to the database if it has not already happened and
    # requires all of the Keycard model classes. It is required to do the
    # connection setup first because of the design decision in Sequel that
    # the schema is examined at the time of extending Sequel::Model.
    def initialize!
      connect! unless connected?
      begin
        model_files.each do |file|
          require_relative file
        end
      rescue Sequel::DatabaseError, NoMethodError => e
        raise DatabaseError, LOAD_ERROR + "\n" + e.message
      end
      db
    end

    # Connect to the Keycard database.
    #
    # The default is to use the settings under {.config}, but can be
    # supplied here (and they will be merged into config as a side effect).
    # The keys that will be used from either source are documented here as
    # the options.
    #
    # Only one "mode" will be used; the first of these supplied will take
    # precedence:
    #
    # 1. An already-connected {Sequel::Database} object
    # 2. A connection string
    # 3. A connection options hash
    #
    # While Keycard serves as a singleton, this will raise a DatabaseError
    # if already connected. Check `connected?` if you are unsure.
    #
    # @see {Sequel.connect}
    # @param [Hash] config Optional connection config
    # @option config [String] :url A Sequel database URL
    # @option config [Hash]   :opts A set of connection options
    # @option config [Sequel::Database] :db An already-connected database;
    # @return [Sequel::Database] The initialized database connection
    def connect!(config = {})
      raise DatabaseError, ALREADY_CONNECTED if connected?
      merge_config!(config)
      raise DatabaseError, MISSING_CONFIG if self.config.db.nil? && conn_opts.empty?

      # We splat here because we might give one or two arguments depending
      # on whether we have a string or not; to add our logger regardless.
      @db = self.config.db || Sequel.connect(*conn_opts)
    end

    # Run any pending migrations.
    # This will connect with the current config if not already conencted.
    def migrate!
      connect! unless connected?
      return if config.readonly

      Sequel.extension :migration
      Sequel::Migrator.run(db, File.join(__dir__, "../../db/migrations"), table: schema_table)
    end

    def schema_table
      :keycard_schema
    end

    def schema_file
      "db/keycard.yml"
    end

    def dump_schema!
      connect! unless connected?
      version = db[schema_table].first.to_yaml
      File.write(schema_file, SCHEMA_HEADER + version)
    end

    def load_schema!
      connect! unless connected?
      version = YAML.load_file(schema_file)[:version]
      db[schema_table].delete
      db[schema_table].insert(version: version)
    end

    def model_files
      []
    end

    # Merge url, opts, or db settings from a hash into our config
    def merge_config!(config = {})
      self.config.url = config[:url] if config.key?(:url)
      self.config.opts = config[:opts] if config.key?(:opts)
      self.config.db = config[:db] if config.key?(:db)
    end

    def conn_opts
      log = {logger: Logger.new("db/keycard.log")}
      url = config.url
      opts = config.opts
      if url
        [url, log]
      elsif opts
        [log.merge(opts)]
      else
        []
      end
    end

    def config
      @config ||= OpenStruct.new(
        url: ENV["KEYCARD_DATABASE_URL"] || ENV["DATABASE_URL"],
        readonly: false
      )
    end

    def connected?
      !@db.nil?
    end

    # The Keycard database
    # @return [Sequel::Database] The connected database; be sure to call initialize! first.
    def db
      raise DatabaseError, CONNECTION_ERROR unless connected?
      @db
    end

    # Forward the Sequel::Database []-syntax down to db for convenience.
    # Everything else must be called on db directly, but this is nice sugar.
    def [](*args)
      db[*args]
    end
  end
end
