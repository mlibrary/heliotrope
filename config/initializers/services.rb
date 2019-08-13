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
end

if Settings.keycard&.database
  Keycard::DB.config.opts = Settings.keycard.database
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
  Checkpoint::Authority.new(
    agent_resolver: ActorAgentResolver.new,
    resource_resolver: TargetResourceResolver.new
  )
end

Services.register(:request_attributes) { Keycard::Request::AttributesFactory.new }

Services.register(:dlps_institution) { DlpsInstitution.new }

Services.register(:score_press) { 'carillon' }
