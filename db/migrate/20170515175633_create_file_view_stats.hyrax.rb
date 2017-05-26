# This migration comes from hyrax (originally 20160328222228)
class CreateFileViewStats < ActiveRecord::Migration[4.2]
  def change
    create_table :file_view_stats do |t|
      t.datetime :date
      t.integer :views
      t.string :file_id

      t.timestamps null: false
    end
    add_index :file_view_stats, :file_id
  end
end
