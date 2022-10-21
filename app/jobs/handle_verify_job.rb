# frozen_string_literal: true

class HandleVerifyJob < ApplicationJob
  def perform(handle) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    record = HandleDeposit.find_by(handle: handle)
    Rails.logger.warn("HandleVerifyJob #{handle} handle deposit record NOT found!") unless record
    return false unless record
    return true if record.verified
    record.verified = rvalue = verify_handle(record.action, handle, record.url_value)
    record.save!
    rvalue
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{handle} #{e}")
    false
  end

  def verify_handle(action, handle, url_value)
    case action
    when 'create'
      verify_handle_create(handle, url_value)
    when 'delete'
      verify_handle_delete(handle)
    else
      Rails.logger.error("HandleVerifyJob #{handle} action #{action} invalid!!!")
      false
    end
  end

  def verify_handle_create(handle, url_value)
    service_url = HandleNet.url_value_for_handle(handle)
    return false if url_value.blank?
    /^#{Regexp.escape(url_value)}$/i.match?(service_url)
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{handle} verify handle create #{e}")
    false
  end

  def verify_handle_delete(handle)
    HandleNet.url_value_for_handle(handle).blank?
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{handle} verify handle delete #{e}")
    false
  end
end
