class RemoveColumnsFromAptrustUploads < ActiveRecord::Migration[5.1]
  def change
    remove_column :aptrust_uploads, :row_number, :int
    remove_column :aptrust_uploads, :date_fileset_modified, :datetime
  end
end
