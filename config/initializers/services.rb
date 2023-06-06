# frozen_string_literal: true

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

Services.register(:request_attributes) { Keycard::Request::AttributesFactory.new }

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
