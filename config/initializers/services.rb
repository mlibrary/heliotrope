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

Services = Canister.new

# Services.register(:presenters) {
#   Vizier::PresenterFactory.new(PRESENTERS, config_type: config_class)
# }
#

# Services.register(:checkpoint) { Checkpoint::Authority.new }
Services.register(:request_attributes) { Keycard::Request::AttributesFactory.new }
