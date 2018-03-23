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
#
# if Heliotrope.config.checkpoint&.database
#   Checkpoint::DB.config.opts = Heliotrope.config.checkpoint.database
# end

if Settings.keycard&.database
  Keycard::DB.config.opts = Settings.keycard.database
end

Keycard::DB.config.readonly = true if Settings.keycard&.readonly

# Services = Canister.new
# Services.register(:presenters) {
#   Vizier::PresenterFactory.new(PRESENTERS, config_type: config_class)
# }
#
# Services.register(:checkpoint) { Checkpoint::Authority.new(agent_resolver: AgentResolver.new) }
