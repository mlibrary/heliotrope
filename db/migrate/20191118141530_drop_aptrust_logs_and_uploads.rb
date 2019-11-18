class DropAptrustLogsAndUploads < ActiveRecord::Migration[5.1]
  def change
    drop_table :aptrust_logs
    drop_table :aptrust_uploads
  end
end
