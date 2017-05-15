# This migration comes from hyrax (originally 20160328222166)
class AddExternalKeyToContentBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :content_blocks, :external_key, :string
    remove_index :content_blocks, :name
  end
end
