class CreateEpubSearchLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :epub_search_logs do |t|
      t.string :noid, index: true
      t.text :query
      t.integer :time
      t.integer :hits
      t.mediumtext :search_results

      t.timestamps
    end
  end
end
