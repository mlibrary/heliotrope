# frozen_string_literal: true

class HandleDeleteJob < ApplicationJob
  def perform(model_id)
    model = Sighrax.from_noid(model_id)
    Rails.logger.warn("HandleDeleteJob #{model_id} is NOT kind of Sighrax::Model") unless model.kind_of?(Sighrax::Model)
    record = HandleDeposit.find_or_create_by(noid: model_id)
    record.action = 'delete'
    record.verified = false
    record.save!
    delete_handle(model)
  rescue StandardError => e
    Rails.logger.error("HandleDeleteJob #{model_id} #{e}")
    false
  end

  def delete_handle(model)
    HandleNet.delete(model.noid)
  end
end
