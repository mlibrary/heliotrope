class CreateKbarts < ActiveRecord::Migration[5.2]
  def change
    create_table :kbarts do |t|
      t.string :noid, unique: true, null: false
      t.text :publication_title
      t.string :print_identifier
      t.string :online_identifier
      t.string :date_first_issue_online
      t.string :num_first_vol_online
      t.string :num_first_issue_online
      t.string :date_last_issue_onlline
      t.string :num_last_vol_online
      t.string :num_last_issue_online
      t.string :title_url
      t.string :first_author
      t.string :title_id
      t.string :embargo_info
      t.string :coverage_depth
      t.string :coverage_notes
      t.string :publisher_name

      t.timestamps
    end
  end
end
