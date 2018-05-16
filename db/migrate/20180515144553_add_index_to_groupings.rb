class AddIndexToGroupings < ActiveRecord::Migration[5.1]
  def change
    add_index :groupings, :identifier, unique: true
  end
end
