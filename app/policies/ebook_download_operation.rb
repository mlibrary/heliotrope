# frozen_string_literal: true

class EbookDownloadOperation < EbookOperation
  def allowed?
    return false unless accessible_offline?

    unrestricted? || licensed_for?(:download)
  end
end
