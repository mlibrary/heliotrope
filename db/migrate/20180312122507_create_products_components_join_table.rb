class CreateProductsComponentsJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :products, :components do |t|
      t.references :product, foreign_key: true
      t.references :component, foreign_key: true
    end
    add_index :components_products, [:product_id, :component_id], unique: true
  end
end
