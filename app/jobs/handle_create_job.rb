# frozen_string_literal: true

class HandleCreateJob < ApplicationJob
  def perform(handle, url_value)
    record = HandleDeposit.find_or_create_by(handle: handle)
    record.action = 'create'
    record.url_value = url_value
    record.verified = false
    record.save!

    service_url = HandleNet.url_value_for_handle(handle)
    return service_url if /^#{Regexp.escape(url_value)}$/i.match?(service_url)

    HandleNet.create_or_update(handle, url_value)
  rescue StandardError => e
    Rails.logger.error("HandleCreateJob #{handle} --> #{url_value} #{e}")
    false
  end
end
