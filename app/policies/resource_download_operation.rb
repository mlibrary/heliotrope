# frozen_string_literal: true

class ResourceDownloadOperation < ApplicationPolicy
  def allowed?
    return EbookDownloadOperation.new(actor, resource).allowed? if resource.is_a?(Sighrax::Ebook)

    return false unless resource.downloadable?

    return true if ability_can?(actor, :update, resource)

    resource.published? && !resource.tombstone? && resource.allow_download?
  end

  protected

    alias_attribute :resource, :target

  private

    def ability_can?(actor, action, target)
      return false unless action.is_a?(Symbol)
      return false unless target.valid?
      # return false unless Incognito.allow_ability_can?(actor)
      ability = Ability.new(actor.is_a?(User) ? actor : nil)
      ability.can?(action, target.noid)
    end
end
