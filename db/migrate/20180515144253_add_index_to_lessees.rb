class AddIndexToLessees < ActiveRecord::Migration[5.1]
  def change
    add_index :lessees, :identifier, unique: true
  end
end
