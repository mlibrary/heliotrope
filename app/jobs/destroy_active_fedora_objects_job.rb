# frozen_string_literal: true

class DestroyActiveFedoraObjectsJob < ApplicationJob
  def perform(ids)
    ids.each do |id|
      ActiveFedora::Base.find(id).destroy
    rescue ActiveFedora::ObjectNotFoundError
      Rails.logger.error("DestroyActiveFedoraObjectsJob #{id} ActiveFedora::ObjectNotFoundError")
    rescue Ldp::Gone
      Rails.logger.error("DestroyActiveFedoraObjectsJob #{id} Ldp::Gone")
    rescue StandardError => e
      Rails.logger.error("DestroyActiveFedoraObjectsJob #{id} StandardError #{e.message}")
    end
  end
end
