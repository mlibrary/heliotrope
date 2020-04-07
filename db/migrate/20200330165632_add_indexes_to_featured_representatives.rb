class AddIndexesToFeaturedRepresentatives < ActiveRecord::Migration[5.1]
  def self.up
    add_index :featured_representatives, :file_set_id, unique: true
    add_index :featured_representatives, [:work_id, :kind], unique: true
  end

  def self.down
    remove_index :featured_representatives, :file_set_id
    remove_index :featured_representatives, [:work_id, :kind]
  end
end
