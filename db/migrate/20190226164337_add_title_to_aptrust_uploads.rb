class AddTitleToAptrustUploads < ActiveRecord::Migration[5.1]
  def change
  	add_column :aptrust_uploads, :title, :string
  end
end
