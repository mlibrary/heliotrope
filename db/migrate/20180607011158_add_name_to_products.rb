class AddNameToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :name, :string
  end
end
