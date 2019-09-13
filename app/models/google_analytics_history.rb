# frozen_string_literal: true

class GoogleAnalyticsHistory < ApplicationRecord
  validates :noid, uniqueness: { scope: %i[original_date page_path pageviews],
                                 message: "date, page_path and pageviews must all be unique" }
end
