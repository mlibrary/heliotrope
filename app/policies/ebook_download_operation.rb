# frozen_string_literal: true

class EbookDownloadOperation < EbookOperation
  def allowed?
    return true if can? :edit

    return false unless accessible_offline?

    unrestricted? || licensed_for?(:download)
  end
end
