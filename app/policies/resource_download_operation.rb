# frozen_string_literal: true

class ResourceDownloadOperation < ApplicationPolicy
  # If we are to build out separate admin pages while keeping the public-facing ones clear of confusing overrides,
  # which make QC more difficult, we need the ability to turn such overrides on and off. Hence `admin_override`.
  # It defaults to true here, as this method is tied into our `Hyrax::DownloadsController`, and admins certainly...
  # do need the ability to _actually_ download all FileSets.
  #
  # However, when this is called from public-facing pages, `false` should be used to prevent admins seeing a download...
  # button/widget when `allow_download` has actually not been set to 'yes'.
  def allowed?(admin_override = true)
    # This line is crucial to prevent a "protected" (possibly "for sale") ebook from being served just like any...
    # Fedora FileSet or unprotected derivative file.
    # note `admin_override` is sent through here as well. See comment below and in `EbookDownloadOperation`.
    return EbookDownloadOperation.new(actor, resource).allowed?(admin_override) if resource.is_a?(Sighrax::Ebook)

    return false unless resource.downloadable?

    # This is the line that uses Hyrax (and our related "platform_admin") permissions stuff
    # We've found that these overrides on pages that are entirely meant to be public-facing are confusing and cause...
    # QC errors. We need the ability to turn them off in those places. Hence `admin_override`.
    return true if admin_override && ability_can?(actor, :update, resource)

    resource.published? && !resource.tombstone? && resource.allow_download?
  end

  protected

    alias_attribute :resource, :target

  private

    def ability_can?(actor, action, target)
      return false unless action.is_a?(Symbol)
      return false unless target.valid?
      return false unless Incognito.allow_ability_can?(actor)
      ability = Ability.new(actor.is_a?(User) ? actor : nil)
      ability.can?(action, target.noid)
    end
end
