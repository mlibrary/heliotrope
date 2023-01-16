class AddGoogleAnalytics4ToPress < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :google_analytics_4, :string
  end
end
