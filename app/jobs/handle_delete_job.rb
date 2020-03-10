# frozen_string_literal: true

class HandleDeleteJob < ApplicationJob
  def perform(model_id)
    record = HandleDeposit.find_or_create_by(noid: model_id)
    record.action = 'delete'
    record.verified = false
    record.save!
    HandleNet.delete(model_id)
  rescue StandardError => e
    Rails.logger.error("HandleDeleteJob #{model_id} #{e}")
    false
  end
end
