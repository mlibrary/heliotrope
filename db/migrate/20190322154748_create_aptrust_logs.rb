class CreateAptrustLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :aptrust_logs do |t|
      t.string :noid
      t.string :status
      t.string :repo
      t.string :stage
      t.string :action
    end
  end
end
