# frozen_string_literal: true

class HandleVerifyJob < ApplicationJob
  def perform(model_id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    record = HandleDeposit.find_by(noid: model_id)
    Rails.logger.warn("HandleVerifyJob #{model_id} handle deposit record NOT found!") unless record
    return false unless record
    return true if record.verified
    record.verified = rvalue = verify_handle(record.action, model_id)
    record.save!
    rvalue
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model_id} #{e}")
    false
  end

  def verify_handle(action, model_id)
    case action
    when 'create'
      verify_handle_create(model_id)
    when 'delete'
      verify_handle_delete(model_id)
    else
      Rails.logger.error("HandleVerifyJob #{model_id} action #{action} invalid!!!")
      false
    end
  end

  def verify_handle_create(model_id)
    model = Sighrax.from_noid(model_id)
    model_url = Sighrax.url(model)
    model_url ||= "https://www.fulcrum.org/#{model.noid}"
    service_url = HandleNet.value(model.noid)
    /^#{Regexp.escape(model_url)}$/i.match?(service_url)
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model.noid} verify handle create #{e}")
    false
  end

  def verify_handle_delete(model_id)
    HandleNet.value(model_id).blank?
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model_id} verify handle delete #{e}")
    false
  end
end
