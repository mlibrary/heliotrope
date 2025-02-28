class DropGoogleAnalyticsHistory < ActiveRecord::Migration[6.0]
  def up
    drop_table :google_analytics_histories, if_exists: true
  end

  def down
    # This table was created in migration db/migrate/20190916160819_create_google_analytics_history.rb
    # We don't use it anymore.
    # This recreation is only here in case you need to do a rollback for some reason 
    create_table :google_analytics_histories do |t|
      t.string :noid, index: true
      t.string :original_date
      t.text :page_path
      t.integer :pageviews

      t.timestamps
    end
  end
end
