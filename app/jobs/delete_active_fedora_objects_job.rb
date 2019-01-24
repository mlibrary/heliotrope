# frozen_string_literal: true

class DeleteActiveFedoraObjectsJob < ApplicationJob
  def perform(noids)
    noids.each { |noid| ActiveFedora::Base.find(noid).delete }
  end
end
