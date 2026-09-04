# frozen_string_literal: true

require "lru_redux"

module Keycard
  # An override of Keycard::InstitutionFinder that trades the gem's long-lived
  # MySQL prepared statement for an ordinary query plus an in-process cache.
  #
  # HELIO-4633. The gem prepares its IP lookup once, in the constructor, and
  # holds onto that Mysql2::Statement for the life of the process:
  #
  #   @stmt = @db[INST_QUERY, *[:$client_ip] * 4].prepare(:select, :unused)
  #
  # Sequel caches the prepared statement per connection and skips re-preparing
  # whenever the SQL is unchanged, so when a pooled connection is recycled --
  # by the MariaDB proxy, or by the server hitting wait_timeout -- the handle
  # refers to a session that no longer exists. Executing it then raises
  #
  #   Mysql2::Error: Commands out of sync; you can't run this command now
  #
  # Building the dataset per call avoids the stale handle entirely. The
  # aa_network table changes rarely and client IPs repeat heavily, so results
  # are memoized in a bounded, thread safe, TTL cache; in practice that leaves
  # far fewer queries than the gem issued even with the prepared statement.
  class CachedInstitutionFinder < InstitutionFinder
    DEFAULT_CACHE_SIZE = 1_000
    DEFAULT_CACHE_TTL = 300

    # Number of :$client_ip placeholders in the inherited INST_QUERY. Derived
    # rather than hardcoded so the binding stays correct if the gem's SQL moves.
    IP_BINDINGS = INST_QUERY.count("?")

    # Deliberately does not call super: the whole point of this class is to not
    # build the prepared statement that Keycard::InstitutionFinder#initialize
    # builds.
    def initialize(db: Keycard::DB.db, cache: nil, cache_size: DEFAULT_CACHE_SIZE, cache_ttl: DEFAULT_CACHE_TTL) # rubocop:disable Lint/MissingSuper
      @db = db
      @cache = cache || LruRedux::TTL::ThreadSafeCache.new(cache_size, cache_ttl)
    end

    # Discard every memoized lookup. Only needed when aa_network changes
    # underneath a running process, which in practice means tests.
    def clear_cache
      cache.clear
    end

    private

      attr_reader :cache, :db

      def insts_for_ip(numeric_ip)
        cached = cache[numeric_ip]
        return cached unless cached.nil?

        insts = db[INST_QUERY, *Array.new(IP_BINDINGS, numeric_ip)].map(:inst).freeze
        cache[numeric_ip] = insts
      end
  end
end
