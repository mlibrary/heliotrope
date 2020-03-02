# frozen_string_literal: true

class HandleVerifyJob < ApplicationJob
  def perform(model_id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    model = Sighrax.from_noid(model_id)
    Rails.logger.warn("HandleVerifyJob #{model_id} is NOT kind of Sighrax::Model") unless model.kind_of?(Sighrax::Model)
    record = HandleDeposit.find_by(noid: model_id)
    Rails.logger.warn("HandleVerifyJob #{model_id} handle deposit record NOT found!") unless record
    return false unless record
    return true if record.verified
    record.verified = rvalue = verify_handle(record.action, model)
    record.save!
    rvalue
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model_id} #{e}")
    false
  end

  def verify_handle(action, model)
    case action
    when 'create'
      verify_handle_create(model)
    when 'delete'
      verify_handle_delete(model)
    else
      Rails.logger.error("HandleVerifyJob #{model.noid} action #{action} invalid!!!")
      false
    end
  end

  def verify_handle_create(model)
    model_url = Sighrax.url(model)
    model_url ||= "https://www.fulcrum.org/#{model.noid}"
    service_url = HandleService.value(model.noid)
    /^#{Regexp.escape(model_url)}$/i.match?(service_url)
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model.noid} verify handle create #{e}")
    false
  end

  def verify_handle_delete(model)
    handle_not_found = "100 : Handle Not Found. (HTTP 404 Not Found)"
    service_url = HandleService.value(model.noid)
    /^#{Regexp.escape(handle_not_found)}$/i.match?(service_url)
  rescue StandardError => e
    Rails.logger.error("HandleVerifyJob #{model.noid} verify handle delete #{e}")
    false
  end
end
