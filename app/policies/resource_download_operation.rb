# frozen_string_literal: true

class ResourceDownloadOperation < ApplicationPolicy
  include AbilityHelpers

  def allowed?
    return EbookDownloadOperation.new(actor, resource).allowed? if resource.is_a?(Sighrax::Ebook)

    return false unless resource.downloadable?

    return true if can? :update

    resource.published? && !resource.tombstone? && resource.allow_download?
  end

  protected

    alias_attribute :resource, :target
end
