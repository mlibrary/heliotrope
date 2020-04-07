class CreateModelTreeEdges < ActiveRecord::Migration[5.1]
  def self.up
    create_table :model_tree_edges do |t|
      t.string :parent_noid, null: false, index: true
      t.string :child_noid, null: false, index: true, unique: true
    end
  end

  def self.down
    drop_table :model_tree_edges
  end
end
