# frozen_string_literal: true

class HandleDeleteJob < ApplicationJob
  def perform(handle)
    # handle = HandleNet::FULCRUM_HANDLE_PREFIX + model_id
    record = HandleDeposit.find_or_create_by(handle: handle)
    record.action = 'delete'
    record.verified = false
    record.save!
    HandleNet.delete(handle)
  rescue StandardError => e
    Rails.logger.error("HandleDeleteJob #{handle} #{e}")
    false
  end
end
