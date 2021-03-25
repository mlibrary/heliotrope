# frozen_string_literal: true

class EntityPolicy < ApplicationPolicy
  def download?
    ResourceDownloadOperation.new(actor, target).allowed?
  end
end
