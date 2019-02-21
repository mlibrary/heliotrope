class CreateAptrustUploads < ActiveRecord::Migration[5.1]
  def self.up
    create_table :aptrust_uploads, id: false do |t|
      t.integer :row_number, autoincrement: true
      t.string :noid, limit: 9, null: false, primary_key: true, unique: true
      t.string :press, limit: 50
      t.string :author, limit: 50
      t.string :model, limit: 50, default: "monograph"
      t.integer :bag_status, default: 0
      t.integer :s3_status, default: 0
      t.integer :apt_status, default: 0
      t.datetime :date_monograph_modified
      t.datetime :date_fileset_modified
      t.datetime :date_bagged
      t.datetime :date_uploaded
      t.datetime :date_confirmed

      t.timestamps
    end
    add_index :aptrust_uploads, :noid, unique: true
    add_index :aptrust_uploads, :bag_status
    add_index :aptrust_uploads, :s3_status
    add_index :aptrust_uploads, :apt_status
  end

  def self.down
    drop_table :aptrust_uploads
  end

end
