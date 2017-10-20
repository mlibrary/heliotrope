# frozen_string_literal: true

Hyrax.config.callback.set(:heliotrope_actor) do |temporal, action, curation_concern, user|
  Rails.logger.info "callback #{temporal} heliotrope actor #{action} #{curation_concern} #{user}"
end
