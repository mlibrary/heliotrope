# frozen_string_literal: true

class EbookIntervalDownloadOperation < EbookOperation
  def allowed?
    return false unless ebook.publisher.interval?

    licensed_for?(:download)
  end
end
