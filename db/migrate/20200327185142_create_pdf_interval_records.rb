class CreatePdfIntervalRecords < ActiveRecord::Migration[5.1]
  def change
    create_table :pdf_interval_records do |t|
      t.string :noid, unique: true, null: false
      t.text :data, unique: false, null: false

      t.timestamps
    end
  end
end
