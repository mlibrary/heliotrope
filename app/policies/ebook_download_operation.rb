# frozen_string_literal: true

class EbookDownloadOperation < EbookOperation
  # see comment below as to why `admin_override` defaults to `false` here
  def allowed?(admin_override = false)
    # This is the line that uses Hyrax (and our related "platform_admin") permissions stuff.
    #
    # We've found that always allowing editors/admins to see/use the ebook downlaod widgets/buttons is confusing and...
    # causes QC errors on pages that are meant to be entirely public-facing. The main reason is that specific FileSet...
    # metadata needs to be set for that download to work for a "public" user, i.e. `allow_download`.
    # This can be missed by an admin who is show the download option regardless of that being set to 'yes'.
    # So, we need the ability to turn them off in those places. Hence `admin_override` with its default of `false`.
    return true if admin_override && can?(:update)

    return false unless accessible_offline?

    unrestricted? || licensed_for?(:download)
  end
end
