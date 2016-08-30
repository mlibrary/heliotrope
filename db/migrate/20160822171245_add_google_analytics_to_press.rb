class AddGoogleAnalyticsToPress < ActiveRecord::Migration
  def change
    add_column :presses, :google_analytics, :string
  end
end
