class AddGoogleAnalyticsToPress < ActiveRecord::Migration[4.2]
  def change
    add_column :presses, :google_analytics, :string
  end
end
