class AddGoogleAnalyticsUrlToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column(:presses, :google_analytics_url, :string)
  end
end
