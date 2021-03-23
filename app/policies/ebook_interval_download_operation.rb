# frozen_string_literal: true

class EbookIntervalDownloadOperation < EbookOperation
  def allowed?
    allows_interval_download? && licensed_for?(:download)
  end

  private

    def allows_interval_download?
      ['barpublishing', 'heb', 'heliotrope'].include? ebook.publisher.subdomain
    end
end
