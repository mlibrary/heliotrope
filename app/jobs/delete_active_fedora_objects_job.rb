# frozen_string_literal: true

class DeleteActiveFedoraObjectsJob < ApplicationJob
  def perform(ids, destroy = false)
    delete_or_destroy = destroy ? :destroy : :delete
    ids.each { |id| ActiveFedora::Base.find(id).public_send(delete_or_destroy) if id.present? }
  end
end
