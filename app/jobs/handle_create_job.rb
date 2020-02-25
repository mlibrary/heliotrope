# frozen_string_literal: true

class HandleCreateJob < ApplicationJob
  def perform(model_id)
    model = Sighrax.from_noid(model_id)
    Rails.logger.warn("HandleCreateJob #{model_id} is NOT kind of Sighrax::Model") unless model.kind_of?(Sighrax::Model)
    return false unless model.kind_of?(Sighrax::Model)
    record = HandleDeposit.find_or_create_by(noid: model_id)
    record.action = 'create'
    record.verified = false
    record.save!
    create_handle(model)
  rescue StandardError => e
    Rails.logger.error("HandleCreateJob #{model_id} #{e}")
    false
  end

  def create_handle(model)
    model_url = Sighrax.url(model) || "https://#{model.noid}"
    service_url = HandleService.value(model.noid)
    return service_url if /^#{Regexp.escape(model_url)}$/i.match?(service_url)
    HandleService.update(model.noid, model_url)
  end
end
