class AddParentIdToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :parent_id, :integer
    add_index :presses, :parent_id
  end
end
