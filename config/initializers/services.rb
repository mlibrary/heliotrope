# frozen_string_literal: true

# HELIO-4633 Keycard overrides. Required rather than autoloaded: they reopen the
# gem's namespace, and the institution finder holds a cache that should survive
# development's code reloading rather than be thrown away between requests.
require Rails.root.join("lib", "keycard", "cached_institution_finder").to_s
require Rails.root.join("lib", "keycard", "request", "memoizing_attributes_factory").to_s

# PRESENTERS = {
#     Listing => [ListingPresenter, ListingPolicy],
#     User    => [UserPresenter, Vizier::ReadOnlyPolicy],
#     'Listing::ActiveRecord_Relation' => [ListingsPresenter, ListingsPolicy],
# }
#
# if Heliotrope.config.cache_presenters
#   config_class = Vizier::CachingPresenterConfig
# else
#   config_class = Vizier::PresenterConfig
# end

if Settings.checkpoint&.database
  Checkpoint::DB.config.opts = Settings.checkpoint.database
  # HELIO-4475 default logger currently goes to db/checkpoint.log which we do not want
  Checkpoint::DB.config.opts[:logger] = Logger.new("log/checkpoint.log")
end

if Settings.keycard&.database
  Keycard::DB.config.opts = Settings.keycard.database
  # HELIO-4475 default logger currently goes to db/keycard.log which we do not want
  Keycard::DB.config.opts[:logger] = Logger.new("log/keycard.log")
end

Keycard::DB.config.readonly = true if Settings.keycard&.readonly
Keycard.config.access = Settings.keycard&.access || :direct

# Note: we do not require db/grant because Sequel requires the connection
# to be set up before defining the model classes. The arrangement here
# assumes that DB.initialize! will have been called if the default model
# is to be used. In tests, that is done by spec/sequel_helper.rb. In an
# application, there should be an initializer that reads whatever appropriate
# configuration and does the initialization.
Checkpoint::DB.initialize!
Keycard::DB.initialize!

# HELIO-4475 Set default log level to debug
Keycard::DB.db.sql_log_level = :debug
Checkpoint::DB.db.sql_log_level = :debug

# HELIO-4633 Guard against stale connections coming back out of the Sequel pool.
#
# Both of these databases are reached through a proxy, so a pooled connection
# can be closed underneath us -- by the proxy, or by MariaDB hitting
# wait_timeout -- while Sequel still believes it is usable. Handing one of those
# out produces errors that look nothing like a disconnect, most often
# "Mysql2::Error: Commands out of sync; you can't run this command now".
#
# The connection_validator extension pings a connection that has been idle
# longer than the timeout below and transparently replaces it if the ping fails.
# Only applied to mysql2, both to keep the cost where the problem is and to
# leave the sqlite databases used in development and test alone.
[Checkpoint::DB.db, Keycard::DB.db].each do |db|
  next unless db.adapter_scheme == :mysql2

  db.extension(:connection_validator)
  # Seconds a connection may sit idle before it is pinged on checkout.
  db.pool.connection_validation_timeout = 30
end

Services = Canister.new

# Services.register(:presenters) {
#   Vizier::PresenterFactory.new(PRESENTERS, config_type: config_class)
# }
#

Services.register(:checkpoint) do
  # def initialize(
  #     agent_resolver: Agent::Resolver.new,
  #     credential_resolver: Credential::Resolver.new,
  #     resource_resolver: Resource::Resolver.new,
  #     permits: Permits.new)
  # end
  ::HeliotropeAuthority.new(
    agent_resolver: ActorAgentResolver.new,
    resource_resolver: TargetResourceResolver.new
  )
end

Services.register(:institution_finder) do
  # HELIO-4874 Replaces Keycard::InstitutionFinder. See the class for why.
  Keycard::CachedInstitutionFinder.new(
    cache_size: Settings.keycard&.institution_cache&.size || Keycard::CachedInstitutionFinder::DEFAULT_CACHE_SIZE,
    cache_ttl: Settings.keycard&.institution_cache&.ttl || Keycard::CachedInstitutionFinder::DEFAULT_CACHE_TTL
  )
end

Services.register(:request_attributes) do
  Keycard::Request::MemoizingAttributesFactory.new(finders: [Services.institution_finder])
end

Services.register(:dlps_institution) { DlpsInstitution.new }

Services.register(:dlps_institution_affiliation) { DlpsInstitutionAffiliation.new }

Services.register(:handle_service) do
  HandleRest::HandleService.new(
    url: Settings.handle_service.url,
    user: Settings.handle_service.user,
    password: Settings.handle_service.password,
    ssl_verify: Settings.handle_service.ssl_verify
  )
end
