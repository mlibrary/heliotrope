class CreateGoogleAnalyticsHistory < ActiveRecord::Migration[5.1]
  def change
    create_table :google_analytics_histories do |t|
      t.string :noid, index: true
      t.string :original_date
      t.text :page_path
      t.integer :pageviews

      t.timestamps
    end
  end
end
