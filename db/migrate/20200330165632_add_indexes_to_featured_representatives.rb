class AddIndexesToFeaturedRepresentatives < ActiveRecord::Migration[5.1]
  def change
    add_index :featured_representatives, :file_set_id, unique: true
    add_index :featured_representatives, [:work_id, :kind], unique: true
  end
end
