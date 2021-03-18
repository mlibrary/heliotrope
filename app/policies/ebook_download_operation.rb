# frozen_string_literal: true

class EbookDownloadOperation < EbookOperation
  def allowed?
    licensed_for?(:download)
  end
end
