class AddIndexToProducts < ActiveRecord::Migration[5.1]
  def change
    add_index :products, :identifier, unique: true
  end
end
