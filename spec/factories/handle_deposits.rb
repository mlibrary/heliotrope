# frozen_string_literal: true

FactoryBot.define do
  factory :handle_deposit do
    # not all handle values will look like this, or contain a 9-digit NOID at all, but the standard Fulcrum ones will
    sequence(:handle) { |n| HandleNet::FULCRUM_HANDLE_PREFIX + format("%09d", n) }
    sequence(:url_value) {
      |n| n.even? ? Rails.application.routes.url_helpers.hyrax_monograph_url(format("%09d", n)) :
            Rails.application.routes.url_helpers.hyrax_file_set_url(format("%09d", n)) }
    sequence(:action) { |n| n.even? ? 'create' : 'delete' }
  end
end
