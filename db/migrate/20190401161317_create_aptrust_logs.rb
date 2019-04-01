class CreateAptrustLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :aptrust_logs do |t|
      t.string :noid, limit: 9
      t.string :where
      t.string :stage
      t.string :status
      t.string :action

      t.timestamps
    end
  end
end
